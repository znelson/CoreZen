//
//  DomainCommon.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <CoreZen/DomainCallbacks.h>

NS_ASSUME_NONNULL_BEGIN

/// Stops the process with an assertion failure unless it's on the main thread.
///
/// Like any `assert`, it does nothing where `NDEBUG` is defined.
#define ASSERT_MAIN_THREAD assert([NSThread isMainThread])

// ========================================
// ZENAsyncContinueBlock
//   Params:
//     - void (no params)
// ========================================

/// Calls a block asynchronously, on a background thread, from a global dispatch queue.
///
/// It does nothing if the block is nil.
void ZENCallAsyncContinueBlockOnThreadPool(ZENAsyncContinueBlock _Nullable continueBlock);

/// Calls a block asynchronously, on the main thread.
///
/// It does nothing if the block is nil.
void ZENCallAsyncContinueBlockOnMainThread(ZENAsyncContinueBlock _Nullable continueBlock);

// ========================================
// ZENAsyncCompletionBlock
//   Params:
//     - NSError* error
// ========================================

/// Calls a block, with an error asynchronously, on a background thread, from a global dispatch queue.
///
/// It does nothing if the block is nil.
void ZENCallAsyncCompletionBlockOnThreadPool(ZENAsyncCompletionBlock _Nullable completionBlock, NSError *_Nullable error);

/// Calls a block, with an error asynchronously, on the main thread.
///
/// It does nothing if the block is nil.
void ZENCallAsyncCompletionBlockOnMainThread(ZENAsyncCompletionBlock _Nullable completionBlock, NSError *_Nullable error);

// ========================================
// ZENFetchResultsBlock
//   Params:
//     - NSArray* fetchedObjects
// ========================================

/// Calls a block, with objects asynchronously, on a background thread, from a global dispatch queue.
///
/// It does nothing if the block is nil.
void ZENCallFetchResultsBlockOnThreadPool(ZENFetchResultsBlock _Nullable fetchResultsBlock, NSArray *fetchedObjects);

/// Calls a block, with objects asynchronously, on the main thread.
///
/// It does nothing if the block is nil.
void ZENCallFetchResultsBlockOnMainThread(ZENFetchResultsBlock _Nullable fetchResultsBlock, NSArray *fetchedObjects);

// ========================================
// ZENAsyncCountCompletionBlock
//   Params:
//     - NSUInteger count
// ========================================

/// Calls a block, with a count asynchronously, on a background thread, from a global dispatch queue.
///
/// It does nothing if the block is nil.
void ZENCallAsyncCountCompletionBlockOnThreadPool(ZENAsyncCountCompletionBlock _Nullable countBlock, NSUInteger count);

/// Calls a block, with a count asynchronously, on the main thread.
///
/// It does nothing if the block is nil.
void ZENCallAsyncCountCompletionBlockOnMainThread(ZENAsyncCountCompletionBlock _Nullable countBlock, NSUInteger count);

// ========================================
// Notifications
// ========================================

/// Posts a notification from the default notification center, asynchronously,
/// on the main thread.
///
/// The sender is the notification's object, and userData its user info.
void ZENDeliverNotificationOnMainThread(NSString *notification, id _Nullable sender, NSDictionary *_Nullable userData);

NS_ASSUME_NONNULL_END
