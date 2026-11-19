//
//  DomainCommon.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <CoreZen/DomainCallbacks.h>

NS_ASSUME_NONNULL_BEGIN

// Convenience macro to confirm threading assumptions
#define ASSERT_MAIN_THREAD assert([NSThread isMainThread])

// ========================================
// ZENAsyncContinueBlock
//   Params:
//     - void (no params)
// ========================================

// Call a ZENAsyncContinueBlock on a thread pool
void ZENCallAsyncContinueBlockOnThreadPool(ZENAsyncContinueBlock _Nullable continueBlock);

// Call a ZENAsyncContinueBlock on the main thread
void ZENCallAsyncContinueBlockOnMainThread(ZENAsyncContinueBlock _Nullable continueBlock);

// ========================================
// ZENAsyncCompletionBlock
//   Params:
//     - NSError* error
// ========================================

// Call a ZENAsyncCompletionBlock on a thread pool
void ZENCallAsyncCompletionBlockOnThreadPool(ZENAsyncCompletionBlock _Nullable completionBlock, NSError *_Nullable error);

// Call a ZENAsyncCompletionBlock on the main thread
void ZENCallAsyncCompletionBlockOnMainThread(ZENAsyncCompletionBlock _Nullable completionBlock, NSError *_Nullable error);

// ========================================
// ZENFetchResultsBlock
//   Params:
//     - NSArray* fetchedObjects
// ========================================

// Call a ZENFetchResultsBlock on a thread pool
void ZENCallFetchResultsBlockOnThreadPool(ZENFetchResultsBlock _Nullable fetchResultsBlock, NSArray *fetchedObjects);

// Call a ZENFetchResultsBlock on the main thread
void ZENCallFetchResultsBlockOnMainThread(ZENFetchResultsBlock _Nullable fetchResultsBlock, NSArray *fetchedObjects);

// ========================================
// ZENAsyncCountCompletionBlock
//   Params:
//     - NSUInteger count
// ========================================

// Call a ZENAsyncCountCompletionBlock on a thread pool
void ZENCallAsyncCountCompletionBlockOnThreadPool(ZENAsyncCountCompletionBlock _Nullable countBlock, NSUInteger count);

// Call a ZENAsyncCountCompletionBlock on the main thread
void ZENCallAsyncCountCompletionBlockOnMainThread(ZENAsyncCountCompletionBlock _Nullable countBlock, NSUInteger count);

// ========================================
// Notifications
// ========================================

// Deliver a notification on the main thread
void ZENDeliverNotificationOnMainThread(NSString *notification, id _Nullable sender, NSDictionary *_Nullable userData);

NS_ASSUME_NONNULL_END
