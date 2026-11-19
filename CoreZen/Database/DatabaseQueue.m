//
//  DatabaseQueue.m
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import "DatabaseQueue+Private.h"
#import "Database+Private.h"
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
- (instancetype)initInMemory;
- (instancetype)initWithURL:(NSURL *)URL;
- (ZENDatabase *)database;
- (void)closeDatabase;
- (NSError *)runTransaction:(ZENDatabaseBlock)updateBlock;
- (void)runAsync:(ZENWorkQueueBlock)work;

@property (nonatomic, strong, readonly) NSURL *databaseURL;
@property (nonatomic, strong, readonly) ZENWorkQueue *workQueue;

@end

@implementation ZENDatabaseQueue

- (void)internalInit:(NSString *)queueLabel {
	_workQueue = [ZENWorkQueue workQueue:queueLabel];
}

- (instancetype)initInMemory {
	self = [super init];
	if (self) {
		NSLog(@"Database in memory");
		_databaseURL = nil;

		static atomic_uint_fast64_t nextIdentifier = 0;
		uint64_t queueID = atomic_fetch_add(&nextIdentifier, 1);

		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-InMemory-%llu", queueID];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueInMemory {
	return [[ZENDatabaseQueue alloc] initInMemory];
}

- (instancetype)initWithURL:(NSURL *)URL {
	self = [super init];
	if (self) {
		NSLog(@"Database at: %@", URL);
		_databaseURL = URL;

		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-%@", [URL lastPathComponent]];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueWithURL:(NSURL *)URL {
	return [[ZENDatabaseQueue alloc] initWithURL:URL];
}

- (void)shutdown {
	[self shutdown:nil];
}

- (void)shutdown:(ZENDatabaseBlock)updateBlock {
	// A second shutdown can't run its block: the first closes the database, and
	// the work queue would run the block on the caller's thread, not in turn
	if (atomic_exchange(&_shutdownStarted, true)) {
		NSLog(@"WARNING: Database queue %@ was already shut down, so its database is closed", self.workQueue.label);
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
			NSLog(@"Opening database at %@", self.databaseURL);
			fmdb = [FMDatabase databaseWithURL:self.databaseURL];
		} else {
			// No path makes a private in-memory database, which lasts until it closes
			NSLog(@"Opening database in memory");
			fmdb = [FMDatabase databaseWithPath:nil];
		}

		if (![fmdb open]) {
			NSLog(@"ERROR: Failed to open database at %@", self.databaseURL);
			return nil;
		}

		_database = [ZENDatabase databaseWithFMDatabase:fmdb];
		[_database executeUpdate:@"PRAGMA synchronous = 1;"];
		[_database setShouldCacheStatements:YES];
	}

	// Set every time, so a change reaches a database opened before it
	[_database setTraceExecution:self.traceExecution];

	return _database;
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
		NSLog(@"ERROR: Couldn't begin a transaction, so each of its statements commits on its own: %@",
			  database.lastErrorMessage);
	}

	updateBlock(database);

	if (!database.inTransaction) {
		// The transaction never began, and what the block's statements did is saved
		return nil;
	}
	NSError *rollbackError = database.rollbackError;
	if (rollbackError) {
		NSLog(@"Rolling back a transaction: %@", rollbackError.localizedDescription);
		[database rollback];
		return rollbackError;
	}
	if (![database commit]) {
		NSString *description = [NSString stringWithFormat:@"Couldn't commit the transaction: %@", database.lastErrorMessage];
		NSLog(@"ERROR: %@, so rolling it back", description);
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
