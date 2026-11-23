//
//  WorkQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 11/14/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A flag that work checks to learn whether it was canceled, or its queue
/// terminated.
///
/// A token starts out not activated, and can be activated once, from any
/// thread. Canceling and terminating are other names for activating, so code
/// reads naturally whichever one the token stands for.
@interface ZENWorkQueueToken : NSObject

/// Whether the token has been activated.
- (BOOL)activated;

/// Whether the token has been activated, for a token that stands for canceling.
- (BOOL)canceled;

/// Whether the token has been activated, for a token that stands for
/// terminating.
- (BOOL)terminated;

/// Activates the token, unless it's activated already.
///
/// It returns YES if this call activated the token, and NO if it was activated
/// already.
- (BOOL)activate;

/// Activates the token, like ``activate``.
- (BOOL)cancel;

/// Activates the token, like ``activate``.
- (BOOL)terminate;

@end

/// A block that a work queue runs.
typedef void (^ZENWorkQueueBlock)(void);

/// A block that a work queue runs asynchronously, with a token that says
/// whether to skip its work.
///
/// The token is activated if the work was canceled, or its queue terminated,
/// before the block ran. The block should check the token's
/// ``ZENWorkQueueToken/canceled``, and return without doing its work if it's YES.
typedef void (^ZENWorkQueueCancelBlock)(ZENWorkQueueToken *canceled);

/// A serial queue whose work can be canceled, and which can be terminated.
///
/// Blocks run one at a time, in the order they're queued. Async work comes with
/// a token to cancel it. Terminating the queue runs a last block once the work
/// already queued has run, and that work sees that it was canceled. Work queued
/// after that doesn't run.
@interface ZENWorkQueue : NSObject

/// The queue's name, which debuggers and crash reports show for its thread.
@property (nonatomic, strong, readonly) NSString *label;

/// Makes a work queue with a name.
+ (ZENWorkQueue *)workQueue:(NSString *)label;

/// Makes a work queue with a name and a quality of service.
+ (ZENWorkQueue *)workQueue:(NSString *)label
						qos:(dispatch_qos_class_t)qos;

/// Runs a block on the queue, and waits for it to finish.
///
/// It returns YES if the block ran, or NO if the queue has been terminated, in
/// which case the block doesn't run. Don't call it from a block running on the
/// same queue, which would wait forever.
- (BOOL)sync:(ZENWorkQueueBlock)block;

/// Queues a block to run asynchronously.
///
/// It returns a token that cancels the work, or nil if the queue has been
/// terminated, in which case the block doesn't run. Once queued, the block
/// always runs, with a token that tells it whether the work was canceled or the
/// queue terminated in the meantime.
- (nullable ZENWorkQueueToken *)async:(ZENWorkQueueCancelBlock)block;

/// Terminates the queue: runs a last block once the work already queued has
/// run, and waits for it.
///
/// The work already queued sees that it was canceled, and calls after this
/// don't run their blocks. A second call logs that the queue was terminated
/// already, and runs its block right away, on the calling thread. Don't call it
/// from a block running on the same queue, which would wait forever.
- (void)terminate:(ZENWorkQueueBlock)block;

@end

NS_ASSUME_NONNULL_END
