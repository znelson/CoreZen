//
//  NSNumber+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 7/18/22.
//

#import "NSNumber+CoreZen.h"

@import Security;

@implementation NSNumber (AlchemistCore)

+ (NSInteger)zen_randomInteger {
	int64_t randomBytes;
	int result = SecRandomCopyBytes(kSecRandomDefault, 8, &randomBytes);
	assert(result == errSecSuccess);
	return randomBytes;
}

@end
