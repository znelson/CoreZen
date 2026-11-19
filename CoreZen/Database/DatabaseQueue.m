//
//  DatabaseQueue.m
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import "DatabaseQueue+Private.h"
#import "Database+Private.h"
#import "ResultSet.h"
#import "Log.h"
#import "WorkQueue.h"

#import <stdatomic.h>

@import FMDB;

@interface ZENDatabaseQueue () {
	// The queue's one connection, and whether shutdown has closed it. Only blocks
	// on the work queue touch these.
	ZENDatabase *_database;
	BOOL _databaseClosed;

	// Set by the first shutdown, from whichever thread calls it
	atomic_bool _shutdownStarted;
}

- (void)internalInit:(NSString *)queueLabel;
- (instancetype)initInMemoryWithOptions:(ZENDatabaseQueueOptions)options;
- (instancetype)initWithURL:(NSURL *)URL options:(ZENDatabaseQueueOptions)options;
- (ZENDatabase *)database;
- (void)configureDatabase:(ZENDatabase *)database;
- (void)closeDatabase;
- (NSError *)runTransaction:(ZENDatabaseBlock)updateBlock;
- (void)runAsync:(ZENWorkQueueBlock)work;

@property (nonatomic, strong, readonly) NSURL *databaseURL;
@property (nonatomic, readonly) ZENDatabaseQueueOptions options;
@property (nonatomic, strong, readonly) ZENWorkQueue *workQueue;

@end

@implementation ZENDatabaseQueue

- (void)internalInit:(NSString *)queueLabel {
	_workQueue = [ZENWorkQueue workQueue:queueLabel];
}

- (instancetype)initInMemoryWithOptions:(ZENDatabaseQueueOptions)options {
	self = [super init];
	if (self) {
		_databaseURL = nil;
		_options = options;

		static atomic_uint_fast64_t nextIdentifier = 0;
		uint64_t queueID = atomic_fetch_add(&nextIdentifier, 1);

		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-InMemory-%llu", queueID];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueInMemory {
	return [self databaseQueueInMemoryWithOptions:0];
}

+ (instancetype)databaseQueueInMemoryWithOptions:(ZENDatabaseQueueOptions)options {
	return [[ZENDatabaseQueue alloc] initInMemoryWithOptions:options];
}

- (instancetype)initWithURL:(NSURL *)URL options:(ZENDatabaseQueueOptions)options {
	self = [super init];
	if (self) {
		_databaseURL = URL;
		_options = options;

		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-%@", [URL lastPathComponent]];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueWithURL:(NSURL *)URL {
	return [self databaseQueueWithURL:URL options:0];
}

+ (instancetype)databaseQueueWithURL:(NSURL *)URL options:(ZENDatabaseQueueOptions)options {
	return [[ZENDatabaseQueue alloc] initWithURL:URL options:options];
}

- (void)shutdown {
	[self shutdown:nil];
}

- (void)shutdown:(ZENDatabaseBlock)updateBlock {
	// A second shutdown can't run its block: the first closes the database, and
	// the work queue would run the block on the caller's thread, not in turn
	if (atomic_exchange(&_shutdownStarted, true)) {
		os_log(ZENLogDatabase(), "Database queue %@ was already shut down, so this shutdown did nothing", self.workQueue.label);
		return;
	}

	[self.workQueue terminate:^{
		if (updateBlock) {
			@autoreleasepool {
				updateBlock(self.database);
			}
		}
		[self closeDatabase];
	}];
}

// Only blocks on the work queue call this. They run one at a time, but GCD may
// run them on different threads. A connection can move between threads like
// that; it just can't be used by two at once, which the serial queue rules out.
- (ZENDatabase *)database {
	if (_databaseClosed) {
		return nil;
	}

	if (_database == nil) {
		FMDatabase *fmdb;
		if (self.databaseURL) {
			os_log_info(ZENLogDatabase(), "Opening the database at %@", self.databaseURL.path);
			fmdb = [FMDatabase databaseWithURL:self.databaseURL];
		} else {
			// No path makes a private in-memory database, which lasts until it closes
			os_log_info(ZENLogDatabase(), "Opening a database in memory");
			fmdb = [FMDatabase databaseWithPath:nil];
		}

		// CoreZen logs failed statements itself, along with the rest of its messages
		fmdb.logsErrors = NO;
		if (![fmdb open]) {
			os_log_error(ZENLogDatabase(), "Couldn't open the database at %@: %{public}@", self.databaseURL.path, fmdb.lastErrorMessage);
			return nil;
		}

		_database = [ZENDatabase databaseWithFMDatabase:fmdb];
		[self configureDatabase:_database];
	}

	// Set every time, so a change reaches a database opened before it
	[_database setTraceExecution:self.traceExecution];

	return _database;
}

// Runs once, as the connection opens. That's before any transaction begins, which
// matters: inside one, SQLite ignores changes to the journal mode and foreign keys.
- (void)configureDatabase:(ZENDatabase *)database {
	// In-memory databases have no file to keep a log next to
	if (self.databaseURL) {
		// The mode is kept in the file, so this changes it only the first time
		ZENResultSet *rs = [database executeQuery:@"PRAGMA journal_mode = WAL;"];
		NSString *mode = [rs next] ? [rs stringForColumnIndex:0] : nil;
		[rs close];
		if (![mode isEqualToString:@"wal"]) {
			os_log(ZENLogDatabase(), "%@ couldn't switch to a write-ahead log, so it keeps its %{public}@ journal",
				   self.databaseURL.lastPathComponent, mode ?: @"current");
		}
	}

	// With the write-ahead log, NORMAL syncs at checkpoints rather than every
	// commit. A power loss can then undo the last commits, but SQLite's
	// documentation says it can't corrupt the database. With the rollback journal
	// it only calls NORMAL "probably" safe, on modern filesystems.
	[database executeUpdate:@"PRAGMA synchronous = NORMAL;"];

	if (self.options & ZENDatabaseQueueOptionForeignKeys) {
		[database executeUpdate:@"PRAGMA foreign_keys = ON;"];
	}

	[database setShouldCacheStatements:YES];
}

// Runs on the work queue, last. Releasing the queue without shutting it down also
// closes the database, when the ZENDatabase deallocates.
- (void)closeDatabase {
	[_database close];
	_database = nil;
	_databaseClosed = YES;
}

// Runs on the work queue. Commits the block's transaction, or rolls it back when
// the block canceled it or one of its statements failed. Returns nil once the
// changes are saved, or an error saying why they weren't.
- (NSError *)runTransaction:(ZENDatabaseBlock)updateBlock {
	ZENDatabase *database = self.database;
	if (!database) {
		// Still run the block, which may call completions of its own
		updateBlock(nil);
		return ZENDatabaseErrorMake(ZENDatabaseErrorNotOpen, @"The database isn't open");
	}

	if (![database beginTransaction]) {
		os_log_error(ZENLogDatabase(), "Couldn't begin a transaction, so each of its statements commits on its own: %{public}@",
					 database.lastErrorMessage);
	}

	updateBlock(database);

	if (!database.inTransaction) {
		// The transaction never began, and what the block's statements did is saved
		return nil;
	}
	NSError *rollbackError = database.rollbackError;
	if (rollbackError) {
		// A canceled transaction is rolled back on purpose; anything else is a failure
		if (rollbackError.code == ZENDatabaseErrorTransactionCanceled) {
			os_log_info(ZENLogDatabase(), "Rolling back a transaction: %{public}@", rollbackError.localizedDescription);
		} else {
			os_log_error(ZENLogDatabase(), "Rolling back a transaction: %{public}@", rollbackError.localizedDescription);
		}
		[database rollback];
		return rollbackError;
	}
	if (![database commit]) {
		NSString *description = [NSString stringWithFormat:@"Couldn't commit the transaction: %@", database.lastErrorMessage];
		os_log_error(ZENLogDatabase(), "%{public}@, so rolling it back", description);
		// A failed commit can leave the transaction open, which would swallow the next one
		if (database.inTransaction) {
			[database rollback];
		}
		return ZENDatabaseErrorMake(ZENDatabaseErrorCommitFailed, description);
	}
	return nil;
}

- (void)transactionAsync:(ZENDatabaseBlock)updateBlock result:(void (^)(NSError *error))resultBlock {
	[self runAsync:^{
		NSError *error = [self runTransaction:updateBlock];
		if (resultBlock) {
			resultBlock(error);
		}
	}];
}

// Queues work that runs even when shutdown starts before its turn: shutdown's own
// block waits behind it. The work queue's token reports shutdown as a cancel, but
// nothing else can cancel database work, so the token goes unused.
- (void)runAsync:(ZENWorkQueueBlock)work {
	[self.workQueue async:^(ZENWorkQueueToken *terminated) {
		// Queued just as shutdown started, but behind its block, so after the close
		if (self->_databaseClosed) {
			return;
		}
		@autoreleasepool {
			work();
		}
	}];
}

- (void)transactionAsync:(ZENDatabaseBlock)updateBlock {
	[self runAsync:^{
		[self runTransaction:updateBlock];
	}];
}

- (void)transactionSync:(ZENDatabaseBlock)updateBlock {
	[self.workQueue sync:^{
		@autoreleasepool {
			[self runTransaction:updateBlock];
		}
	}];
}

- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock {
	[self runAsync:^{
		fetchBlock(self.database);
	}];
}

- (void)fetchSync:(ZENDatabaseBlock)fetchBlock {
	[self.workQueue sync:^{
		@autoreleasepool {
			ZENDatabase *database = self.database;
			fetchBlock(database);
		}
	}];
}

- (void)vacuumAsync {
	[self runAsync:^{
		[self.database executeUpdate:@"VACUUM;"];
	}];
}

@end
