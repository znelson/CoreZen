//
//  DatabaseQueue+Private.h
//  CoreZen
//

#import "DatabaseQueue.h"

@interface ZENDatabaseQueue (Private)

// Same as transactionAsync:, then calls resultBlock with nil once the transaction
// has committed, or with an error (in ZENDatabaseErrorDomain) saying why nothing
// was saved: it rolled back, or the database isn't open. resultBlock runs on the
// queue, right after the transaction ends and before any work queued after it,
// so it mustn't call this queue's sync methods. resultBlock may be nil.
//
// Private, for repositories: their writes, and write batches, use it to change
// their caches and post notifications only once a change is saved. Code outside
// CoreZen saves objects through a repository, so they always agree.
- (void)transactionAsync:(ZENDatabaseBlock)updateBlock result:(void (^)(NSError *error))resultBlock;

@end
