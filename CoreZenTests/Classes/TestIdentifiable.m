//
//  TestIdentifiable.m
//  CoreZenTests
//
//  Created by Zach Nelson on 3/23/22.
//

#import "TestIdentifiable.h"

@import CoreZen;

@implementation ZENTestIdentifiable

@synthesize identifier=_identifier;

- (instancetype)init {
	ZENIdentifier identifier = ZENGetNextObjectIdentifier();
	self = [self initWithIdentifier:identifier];
	return self;
}

+ (instancetype)testIdentifiableWithIdentifier:(ZENIdentifier)identifier {
	ZENTestIdentifiable* obj = [[ZENTestIdentifiable alloc] initWithIdentifier:identifier];
	return obj;
}

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier {
	self = [super init];
	if (self) {
		_identifier = identifier;
	}
	return self;
}

@end

