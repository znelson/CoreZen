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

// Each in-memory queue has a database of its own, gone once the queue closes it
+ (instancetype)databaseQueueInMemory;
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;

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

// Same as transactionAsync:, then calls resultBlock with nil once the transaction
// has committed, or with an error (in ZENDatabaseErrorDomain) saying why nothing
// was saved: it rolled back, or the database isn't open. resultBlock runs on the
// queue, right after the transaction ends and before any work queued after it,
// so it mustn't call this queue's sync methods. resultBlock may be nil.
- (void)transactionAsync:(ZENDatabaseBlock)updateBlock result:(nullable void (^)(NSError *_Nullable error))resultBlock;
- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock;
- (void)fetchSync:(ZENDatabaseBlock)fetchBlock;
- (void)vacuumAsync;

// Log each SQL statement as it runs. Off by default. A change takes effect from
// the next block the queue runs.
@property (atomic) BOOL traceExecution;

@end

NS_ASSUME_NONNULL_END
