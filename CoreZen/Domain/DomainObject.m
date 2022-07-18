//
//  DomainObject.m
//  CoreZen
//
//  Created by Zach Nelson on 4/19/22.
//

#import "DomainObject.h"
#import "DomainCommon.h"

@interface ZENDomainObject ()

// Redeclare as readwrite
@property (nonatomic, strong) ZENDataTransferObject *basicDTO;

@end

@implementation ZENDomainObject

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto {
	self = [self init];
	if (self) {
		self.basicDTO = dto;
	}
	return self;
}

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncContinueBlock)completion {
	// performAsyncInit is available to override by derived classes
	completion();
}

+ (void)asyncInit:(NSArray *)objects
			model:(id<ZENDataModel>)model
	   completion:(ZENAsyncContinueBlock)completion {
	__block NSUInteger initsInFlight = objects.count;
	__block NSCondition *condition = [NSCondition new];
	
	for (ZENDomainObject* domainObject in objects) {
		ZENCallAsyncContinueBlockOnThreadPool(^{
			[domainObject performAsyncInit:model completion:^{
				[condition lock];
				if (0 == --initsInFlight) {
					[condition signal];
				}
				[condition unlock];
			}];
		});
	}
	
	if (completion) {
		ZENCallAsyncContinueBlockOnThreadPool(^{
			[condition lock];
			while (initsInFlight > 0) {
				[condition wait];
			}
			[condition unlock];
			completion();
		});
	}
}

- (ZENIdentifier)identifier {
	return self.basicDTO.identifier;
}

@end
