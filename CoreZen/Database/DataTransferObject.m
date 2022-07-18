//
//  DataTransferObject.m
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import "DataTransferObject.h"

@interface CZNDTO ()

@property (nonatomic) CZNIdentifier identifier;

@end

@implementation CZNDTO

- (instancetype)init {
	self = [super init];
	if (self) {
		_identifier = CZNInvalidIdentifier;
	}
	return self;
}

- (instancetype)initWithIdentifier:(CZNIdentifier)identifier {
	self = [self init];
	if (self) {
		_identifier = identifier;
	}
	return self;
}

@end
