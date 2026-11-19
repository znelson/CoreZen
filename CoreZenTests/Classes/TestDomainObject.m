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

- (void)didUpdateDTO {
	[super didUpdateDTO];
	_name = [((ZENTestDTO *)self.basicDTO).name copy];
	@synchronized(self) {
		_dtoUpdateCount += 1;
	}
}

@end

static const NSTimeInterval kSlowInitDelay = 0.2;

@interface ZENSlowInitDomainObject ()

@property (atomic) BOOL initialized;
@property (atomic) NSInteger asyncInitCount;

// The error performAsyncInit: finishes with, after its delay
- (NSError *)asyncInitError;

@end

@implementation ZENSlowInitDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion {
	@synchronized(self) {
		self.asyncInitCount += 1;
	}
	dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSlowInitDelay * NSEC_PER_SEC));
	dispatch_after(delay, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		NSError *error = [self asyncInitError];
		self.initialized = (error == nil);
		completion(error);
	});
}

- (NSError *)asyncInitError {
	return nil;
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

static NSError *ZENTestInitError(ZENTestDomainObject *object) {
	NSString *description = [NSString stringWithFormat:@"%@ fails its async init", object.name];
	return [NSError errorWithDomain:ZENTestErrorDomain code:1 userInfo:@{ NSLocalizedDescriptionKey: description }];
}

@implementation ZENFailableInitDomainObject

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion {
	completion([self.name hasPrefix:@"Fail"] ? ZENTestInitError(self) : nil);
}

@end

@implementation ZENSlowFailingInitDomainObject

- (NSError *)asyncInitError {
	return ZENTestInitError(self);
}

@end
