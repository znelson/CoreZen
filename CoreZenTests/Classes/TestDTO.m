//
//  TestDTO.m
//  CoreZenTests
//

#import "TestDTO.h"

@implementation ZENTestDTO

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier name:(NSString *)name {
	self = [super initWithIdentifier:identifier];
	if (self) {
		_name = [name copy];
	}
	return self;
}

@end
