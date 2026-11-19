//
//  DatabaseQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;

NS_ASSUME_NONNULL_BEGIN

/// A block that a database queue runs with its database.
///
/// The database is nil only if the queue couldn't open it.
typedef void (^ZENDatabaseBlock)(ZENDatabase *_Nullable database);

/// Runs blocks on a database one at a time, in the order they're queued.
///
/// Every block gets the queue's one connection, which opens when a block first
/// needs it and closes at shutdown, or when the queue is released. So anything
/// that belongs to a connection, like a temporary table, lasts from one block to
/// the next. Async blocks run on a background thread.
@interface ZENDatabaseQueue : NSObject

/// Options for a database queue's connection.
typedef NS_OPTIONS(NSUInteger, ZENDatabaseQueueOptions) {
	/// Enforce the `REFERENCES` clauses in the database's tables, which SQLite
	/// ignores unless asked.
	///
	/// A change that would leave a row referring to one that doesn't exist fails,
	/// or does what the clause's `ON DELETE` or `ON UPDATE` action says. Schema
	/// updates run in a transaction, where SQLite can't turn this off, so a
	/// migration that drops a table other tables refer to, as rebuilding a table
	/// does, deletes its rows under those rules first.
	ZENDatabaseQueueOptionForeignKeys = 1 << 0,
};

/// Makes a queue with a new database in memory.
///
/// Each in-memory queue has a database of its own, gone once the queue closes it.
+ (instancetype)databaseQueueInMemory;

/// Makes a queue with a new database in memory, with options.
///
/// Each in-memory queue has a database of its own, gone once the queue closes it.
+ (instancetype)databaseQueueInMemoryWithOptions:(ZENDatabaseQueueOptions)options;

/// Makes a queue for the database file at a URL, which it creates if there's
/// none.
///
/// The file's folder must exist already. A database file uses SQLite's
/// write-ahead log (WAL), which it keeps in the file once switched. A write
/// doesn't wait for other connections' reads, nor they for it. A power loss or
/// system crash can undo the last few commits, but can't corrupt the database.
/// WAL needs the file on a local volume, and adds two more next to it:
/// `name-wal` and `name-shm`. Copy or move all three together. Once the database
/// closes cleanly, the first alone holds all its data, but after a crash,
/// `name-wal` can hold the latest commits.
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;

/// Makes a queue for the database file at a URL, with options.
///
/// Like ``databaseQueueWithURL:``, it creates the file if there's none.
+ (instancetype)databaseQueueWithURL:(NSURL *)URL options:(ZENDatabaseQueueOptions)options;

/// Closes the database, once the async blocks already queued have run.
///
/// Calls after this don't run their blocks, and neither does a sync call still
/// waiting for its turn on another thread. A second shutdown does nothing.
- (void)shutdown;

/// Runs a last block before closing the database, once the async blocks already
/// queued have run.
///
/// Calls after this don't run their blocks, and neither does a sync call still
/// waiting for its turn on another thread. A second shutdown does nothing, and
/// doesn't run its block.
- (void)shutdown:(nullable ZENDatabaseBlock)updateBlock;

/// Runs a block in a transaction, asynchronously.
///
/// The transaction commits when the block returns. It rolls back instead if any
/// statement in it fails, or if the block calls the database's
/// ``ZENDatabase/cancelTransaction``.
- (void)transactionAsync:(ZENDatabaseBlock)updateBlock;

/// Runs a block in a transaction, and waits for it to finish.
///
/// The transaction commits when the block returns. It rolls back instead if any
/// statement in it fails, or if the block calls the database's
/// ``ZENDatabase/cancelTransaction``.
- (void)transactionSync:(ZENDatabaseBlock)updateBlock;

/// Runs a block outside a transaction, asynchronously.
///
/// Each statement the block runs commits on its own.
- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock;

/// Runs a block outside a transaction, and waits for it to finish.
///
/// Each statement the block runs commits on its own.
- (void)fetchSync:(ZENDatabaseBlock)fetchBlock;

/// Rebuilds the database file to give back the space deleted rows left,
/// asynchronously.
- (void)vacuumAsync;

/// Whether to log each SQL statement as it runs.
///
/// It's off by default. A change takes effect from the next block the queue
/// runs.
@property (atomic) BOOL traceExecution;

@end

NS_ASSUME_NONNULL_END
