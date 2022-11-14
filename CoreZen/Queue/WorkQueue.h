//
//  WorkQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 11/14/22.
//

#import <Foundation/Foundation.h>

@interface ZENWorkQueueToken : NSObject

// WorkQueueToken begins deactivated and becomeds activated
// Used to indicate a state like `canceled` or `terminated`
- (BOOL)activated;

// Synonyms for -activated
- (BOOL)canceled;
- (BOOL)terminated;

// Token can be activated only once
- (BOOL)activate;

// Synonyms for -activate
- (BOOL)cancel;
- (BOOL)terminate;

@end

typedef ZENWorkQueueToken ZENCancelToken;

typedef void (^ZENWorkQueueBlock)(void);
typedef void (^ZENWorkQueueCancelBlock)(ZENCancelToken *canceled);

@interface ZENWorkQueue : NSObject

@property (nonatomic, strong, readonly) NSString *label;

+ (ZENWorkQueue *)workQueue:(NSString *)label;

+ (ZENWorkQueue *)workQueue:(NSString *)label
						qos:(dispatch_qos_class_t)qos;

// Return value indicates if `block` was called
// (Block will not be called if the queue has been terminated)
- (BOOL)sync:(ZENWorkQueueBlock)block;

// Returns a WorkQueueToken if the block was queued to run
// This token can be used to atomically flag the work as canceled
// The WorkQueueToken
// Return value indicates if `block` will be called
// (Block will not be called if the queue has been terminated)
- (ZENWorkQueueToken *)async:(ZENWorkQueueCancelBlock)block;

- (void)terminate:(ZENWorkQueueBlock)block;

@end
