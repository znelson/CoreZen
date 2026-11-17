//
//  DomainObject.m
//  CoreZen
//
//  Created by Zach Nelson on 4/19/22.
//

#import "DomainObject.h"
#import "DomainCommon.h"
#import "WorkQueue.h"

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
	// Each object leaves the group when its init completes. dispatch_group_notify
	// waits without tying up a thread while the inits run.
	dispatch_group_t group = dispatch_group_create();

	for (id<ZENDomainObject> domainObject in objects) {
		dispatch_group_enter(group);
		// A token activates only once, so only an object's first completion
		// call leaves the group
		ZENWorkQueueToken *completed = [ZENWorkQueueToken new];
		ZENCallAsyncContinueBlockOnThreadPool(^{
			[domainObject performAsyncInit:model completion:^{
				if ([completed activate]) {
					dispatch_group_leave(group);
				} else {
					NSLog(@"WARNING: %@ called its performAsyncInit: completion more than once", domainObject);
				}
			}];
		});
	}

	if (completion) {
		dispatch_group_notify(group, dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
			@autoreleasepool {
				completion();
			}
		});
	}
}

- (ZENIdentifier)identifier {
	return self.basicDTO.identifier;
}

@end
