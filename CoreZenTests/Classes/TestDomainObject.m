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
			  completion:(ZENAsyncContinueBlock)completion {
	@synchronized(self) {
		self.asyncInitCount += 1;
	}
	dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSlowInitDelay * NSEC_PER_SEC));
	dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		self.initialized = YES;
		completion();
	});
}

@end

@implementation ZENDoubleCompletionDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncContinueBlock)completion {
	completion();
	completion();
}

@end
