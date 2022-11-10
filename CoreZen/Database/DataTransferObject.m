//
//  DataTransferObject.m
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import "DataTransferObject.h"

@implementation ZENDataTransferObject

@synthesize identifier=_identifier;

- (instancetype)init {
	self = [super init];
	if (self) {
		_identifier = ZENInvalidIdentifier;
	}
	return self;
}

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier {
	self = [self init];
	if (self) {
		_identifier = identifier;
	}
	return self;
}

@end
