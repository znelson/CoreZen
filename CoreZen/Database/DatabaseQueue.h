//
//  DatabaseQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;

typedef void (^ZENDatabaseBlock)(ZENDatabase *database);

// Runs blocks on a database one at a time, in the order they're queued. Every
// block gets the queue's one connection, which opens when a block first needs it
// and closes at shutdown, or when the queue is released. So anything that belongs
// to a connection, like a temporary table, lasts from one block to the next.
@interface ZENDatabaseQueue : NSObject

// Each in-memory queue has a database of its own, gone once the queue closes it
+ (instancetype)databaseQueueInMemory;
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;

// Lets a running block finish, then runs updateBlock if there is one and closes
// the database. Blocks that haven't started yet don't run, including async ones
// queued before this. A second shutdown does nothing, and doesn't run its block.
- (void)shutdown;
- (void)shutdown:(ZENDatabaseBlock)updateBlock;

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
