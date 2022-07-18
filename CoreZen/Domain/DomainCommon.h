//
//  DomainCommon.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <CoreZen/DomainCallbacks.h>

// Convenience macro to confirm threading assumptions
#define ASSERT_MAIN_THREAD assert([NSThread isMainThread])

// ========================================
// ZENAsyncContinueBlock
//   Params:
//     - void (no params)
// ========================================

// Call a ZENAsyncContinueBlock on a thread pool
void ZENCallAsyncContinueBlockOnThreadPool(ZENAsyncContinueBlock continueBlock);

// Call a ZENAsyncContinueBlock on the main thread
void ZENCallAsyncContinueBlockOnMainThread(ZENAsyncContinueBlock continueBlock);

// ========================================
// ZENAsyncCompletionBlock
//   Params:
//     - NSError* error
// ========================================

// Call a ZENAsyncCompletionBlock on a thread pool
void ZENCallAsyncCompletionBlockOnThreadPool(ZENAsyncCompletionBlock completionBlock, NSError* error);

// Call a ZENAsyncCompletionBlock on the main thread
void ZENCallAsyncCompletionBlockOnMainThread(ZENAsyncCompletionBlock completionBlock, NSError* error);

// ========================================
// ZENFetchResultsBlock
//   Params:
//     - NSArray* fetchedObjects
// ========================================

// Call a ZENFetchResultsBlock on a thread pool
void ZENCallFetchResultsBlockOnThreadPool(ZENFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects);

// Call a ZENFetchResultsBlock on the main thread
void ZENCallFetchResultsBlockOnMainThread(ZENFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects);

// ========================================
// ZENAsyncCountCompletionBlock
//   Params:
//     - NSUInteger count
// ========================================

// Call a ZENAsyncCountCompletionBlock on the main thread
void ZENCallAsyncCountCompletionBlockOnThreadPool(ZENAsyncCountCompletionBlock countBlock, NSUInteger count);

// Call a ZENAsyncCountCompletionBlock on the main thread
void ZENCallAsyncCountCompletionBlockOnMainThread(ZENAsyncCountCompletionBlock countBlock, NSUInteger count);

// ========================================
// Notifications
// ========================================

// Deliver a notification on the main thread
void ZENDeliverNotificationOnMainThread(NSString* notification, id sender, NSDictionary *userData);
