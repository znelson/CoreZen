//
//  TestDomainObject.m
//  CoreZenTests
//

#import "TestDomainObject.h"
#import "TestDTO.h"

@implementation ZENTestDomainObject

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto {
	self = [super initWithDTO:dto];
	if (self) {
		ZENTestDTO *testDTO = (ZENTestDTO *)dto;
		_name = [testDTO.name copy];
	}
	return self;
}

@end

static const NSTimeInterval kSlowInitDelay = 0.2;

@interface ZENSlowInitDomainObject ()

@property (atomic) BOOL initialized;
@property (atomic) NSInteger asyncInitCount;

@end

@implementation ZENSlowInitDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion {
	@synchronized(self) {
		self.asyncInitCount += 1;
	}
	dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSlowInitDelay * NSEC_PER_SEC));
	dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		self.initialized = YES;
		completion(nil);
	});
}

@end

@implementation ZENDoubleCompletionDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion {
	completion(nil);
	completion(nil);
}

@end

NSString *const ZENTestErrorDomain = @"ZENTestErrorDomain";

@implementation ZENFailableInitDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion {
	if ([self.name hasPrefix:@"Fail"]) {
		NSString *description = [NSString stringWithFormat:@"%@ fails its async init", self.name];
		completion([NSError errorWithDomain:ZENTestErrorDomain code:1 userInfo:@{ NSLocalizedDescriptionKey: description }]);
	} else {
		completion(nil);
	}
}

@end
