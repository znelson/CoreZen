//
//  DatabaseQueue+Private.h
//  CoreZen
//

#import "DatabaseQueue.h"

@interface ZENDatabaseQueue (Private)

// Runs updateBlock in a transaction, like transactionAsync:, then calls
// resultBlock with nil once the transaction has committed, or with an error once
// it has rolled back. resultBlock runs on the work queue, before the queue's next
// block, so what it does keeps step with the database. It mustn't call this
// queue's sync methods, which would wait on it forever.
- (void)transactionAsync:(ZENDatabaseBlock)updateBlock result:(void (^)(NSError *error))resultBlock;

@end
