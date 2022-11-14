//
//  ZENWorkQueue.m
//  CoreZen
//
//  Created by Zach Nelson on 11/14/22.
//

#import "WorkQueue.h"

#import <stdatomic.h>

typedef BOOL (^ZENWorkQueueTokenBlock)(void);

@interface ZENWorkQueueToken ()
{
	atomic_bool _token;
}
@end

@implementation ZENWorkQueueToken

- (instancetype)init {
	self = [super init];
	if (self) {
		atomic_store(&_token, false);
	}
	return self;
}

- (BOOL)activated {
	return atomic_load(&_token);
}

- (BOOL)canceled {
	return self.activated;
}

- (BOOL)terminated {
	return self.activated;
}

- (BOOL)activate {
	bool deactivated = false;
	bool activated = true;
	return atomic_compare_exchange_strong(&_token, &deactivated, activated);
}

- (BOOL)cancel {
	return [self activate];
}

- (BOOL)terminate {
	return [self activate];
}

@end

@interface ZENCompositeWorkQueueToken : ZENWorkQueueToken

@property (nonatomic, strong, readonly) NSArray<ZENWorkQueueToken *> *tokens;

- (instancetype)initWithTokens:(NSArray<ZENWorkQueueToken *> *)tokens;

@end

@implementation ZENCompositeWorkQueueToken

- (instancetype)initWithTokens:(NSArray<ZENWorkQueueToken *> *)tokens {
	self = [super init];
	if (self) {
		_tokens = tokens;
	}
	return self;
}

- (BOOL)activated {
	for (ZENWorkQueueToken *token in self.tokens) {
		if (token.activated) {
			return YES;
		}
	}
	return NO;
}

- (BOOL)activate {
	assert(false);
	NSLog(@"ZENCompositeWorkQueueToken -activate should not be used");
}

@end

@interface ZENWorkQueue ()

@property (nonatomic, strong, readonly) dispatch_queue_t queue;
@property (nonatomic, strong, readonly) ZENWorkQueueToken *terminateToken;

- (void)initCommon:(NSString *)label;

- (instancetype)initWithLabel:(NSString *)label;

- (instancetype)initWithLabel:(NSString *)label
						  qos:(dispatch_qos_class_t)qos;

@end

@implementation ZENWorkQueue

- (void)initCommon:(NSString *)label {
	_label = label;
	_terminateToken = [ZENWorkQueueToken new];
}

- (instancetype)initWithLabel:(NSString *)label {
	self = [super init];
	if (self) {
		[self initCommon:label];
		_queue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_SERIAL);
	}
	return self;
}

- (instancetype)initWithLabel:(NSString *)label
						  qos:(dispatch_qos_class_t)qos {
	self = [super init];
	if (self) {
		[self initCommon:label];
		dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos, 0);
		_queue = dispatch_queue_create(label.UTF8String, attr);
	}
	return self;
}

- (instancetype)init {
	return [self initWithLabel:@"ZENWorkQueue"];
}

+ (ZENWorkQueue *)workQueue:(NSString *)label {
	return [[ZENWorkQueue alloc] initWithLabel:label];
}

+ (ZENWorkQueue *)workQueue:(NSString *)label
						qos:(dispatch_qos_class_t)qos {
	return [[ZENWorkQueue alloc] initWithLabel:label qos:qos];
}

- (BOOL)sync:(ZENWorkQueueBlock)block {
	if (self.terminateToken.terminated) {
		return NO;
	}
	
	__block BOOL called = NO;
	
	dispatch_sync(self.queue, ^{
		if (!self.terminateToken.terminated) {
			called = YES;
			block();
		}
	});
	
	return called;
}

- (ZENWorkQueueToken *)async:(ZENWorkQueueCancelBlock)block {
	if (self.terminateToken.terminated) {
		return nil;
	}
	
	ZENWorkQueueToken *cancelToken = [ZENWorkQueueToken new];
	
	dispatch_async(self.queue, ^{
		NSArray *tokens = @[self.terminateToken, cancelToken];
		ZENWorkQueueToken *compositeToken = [[ZENCompositeWorkQueueToken alloc] initWithTokens:tokens];
		block(compositeToken);
	});
	
	return cancelToken;
}

- (void)terminate:(ZENWorkQueueBlock)block {
	if (![self.terminateToken terminate]) {
		NSLog(@"WARNING: Work queue %@ terminated more than once", self.label);
		block();
		return;
	}
	
	dispatch_sync(self.queue, ^{
		block();
		NSLog(@"Terminated work queue %@", self.label);
	});
}

@end
