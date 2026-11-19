//
//  DatabaseQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;

NS_ASSUME_NONNULL_BEGIN

// database is nil only if the queue couldn't open its database
typedef void (^ZENDatabaseBlock)(ZENDatabase *_Nullable database);

// Runs blocks on a database one at a time, in the order they're queued. Every
// block gets the queue's one connection, which opens when a block first needs it
// and closes at shutdown, or when the queue is released. So anything that belongs
// to a connection, like a temporary table, lasts from one block to the next.
@interface ZENDatabaseQueue : NSObject

typedef NS_OPTIONS(NSUInteger, ZENDatabaseQueueOptions) {
	// Enforce the REFERENCES clauses in the database's tables, which SQLite
	// ignores unless asked. A change that would leave a row referring to one that
	// doesn't exist fails, or does what the clause's ON DELETE or ON UPDATE action
	// says. Schema updates run in a transaction, where SQLite can't turn this off,
	// so a migration that drops a table other tables refer to, as rebuilding a
	// table does, deletes its rows under those rules first.
	ZENDatabaseQueueOptionForeignKeys = 1 << 0,
};

// Each in-memory queue has a database of its own, gone once the queue closes it
+ (instancetype)databaseQueueInMemory;
+ (instancetype)databaseQueueInMemoryWithOptions:(ZENDatabaseQueueOptions)options;

// A database file uses SQLite's write-ahead log (WAL), which it keeps in the
// file once switched. A write doesn't wait for other connections' reads, nor
// they for it. A power loss or system crash can undo the last few commits, but
// can't corrupt the database. WAL needs the file on a local volume, and adds two
// more next to it: name-wal and name-shm. Copy or move all three together. Once
// the database closes cleanly, the first alone holds all its data, but after a
// crash, name-wal can hold the latest commits.
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;
+ (instancetype)databaseQueueWithURL:(NSURL *)URL options:(ZENDatabaseQueueOptions)options;

// Runs the async blocks already queued, then updateBlock if there is one, then
// closes the database. Calls after this don't run their blocks, and neither does
// a sync call still waiting for its turn on another thread. A second shutdown
// does nothing, and doesn't run its block.
- (void)shutdown;
- (void)shutdown:(nullable ZENDatabaseBlock)updateBlock;

// Run a block in a transaction, which commits when the block returns. It rolls
// back instead if any statement in it fails, or if the block calls the
// database's cancelTransaction.
- (void)transactionAsync:(ZENDatabaseBlock)updateBlock;
- (void)transactionSync:(ZENDatabaseBlock)updateBlock;
- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock;
- (void)fetchSync:(ZENDatabaseBlock)fetchBlock;
- (void)vacuumAsync;

// Log each SQL statement as it runs. Off by default. A change takes effect from
// the next block the queue runs.
@property (atomic) BOOL traceExecution;

@end

NS_ASSUME_NONNULL_END
