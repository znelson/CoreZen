//
//  NSNumber+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 7/18/22.
//

#import "NSNumber+CoreZen.h"

#include <stdlib.h>

@implementation NSNumber (CoreZen)

+ (NSInteger)zen_randomInteger {
	// arc4random_buf is a cryptographically secure generator that can't fail, so
	// unlike SecRandomCopyBytes there's no error to check (or miss in Release builds)
	NSInteger randomInteger;
	arc4random_buf(&randomInteger, sizeof(randomInteger));
	return randomInteger;
}

@end
