//
//  DataTransferObject.m
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import "DataTransferObject.h"

#import <objc/runtime.h>

@implementation ZENDataTransferObject

@synthesize identifier = _identifier;

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

- (id)copyWithZone:(NSZone *)zone {
	ZENDataTransferObject *copy = [(ZENDataTransferObject *)[self.class allocWithZone:zone] initWithIdentifier:self.identifier];
	[copy takeValuesFromDTO:self];
	return copy;
}

- (void)takeValuesFromDTO:(ZENDataTransferObject *)dto {
	NSParameterAssert(dto.class == self.class);
	if (dto.class != self.class) {
		return;
	}
	// The subclass's properties, and those of any classes between it and this one
	for (Class cls = self.class; cls && cls != ZENDataTransferObject.class; cls = cls.superclass) {
		unsigned int count = 0;
		objc_property_t *properties = class_copyPropertyList(cls, &count);
		for (unsigned int index = 0; index < count; index++) {
			// A read-only property isn't one of the DTO's values to set
			char *readOnly = property_copyAttributeValue(properties[index], "R");
			if (readOnly) {
				free(readOnly);
				continue;
			}
			NSString *name = @(property_getName(properties[index]));
			[self setValue:[dto valueForKey:name] forKey:name];
		}
		free(properties);
	}
}

@end
