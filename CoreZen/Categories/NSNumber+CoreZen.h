//
//  NSNumber+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 7/18/22.
//

#import <Foundation/Foundation.h>

@interface NSNumber (CoreZen)

/// A random integer, from a cryptographically secure generator.
///
/// It can be any `NSInteger` value, negative ones included.
+ (NSInteger)zen_randomInteger;

@end
