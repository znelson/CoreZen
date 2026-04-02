//
//  NSNumber+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 7/18/22.
//

#import "NSNumber+CoreZen.h"

@import Security;

@implementation NSNumber (CoreZen)

+ (NSInteger)zen_randomInteger {
	int64_t randomBytes;
	int result = SecRandomCopyBytes(kSecRandomDefault, 8, &randomBytes);
	NSCAssert(result == errSecSuccess, @"SecRandomCopyBytes failed with status %d", result);
	return randomBytes;
}

@end
