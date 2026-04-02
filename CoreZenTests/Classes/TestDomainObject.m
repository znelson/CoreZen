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
