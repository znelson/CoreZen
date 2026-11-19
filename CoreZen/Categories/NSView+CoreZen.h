//
//  NSView+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 11/15/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (CoreZen)

- (void)zen_addConstraintsForEqualSizes:(NSView *)other;

@end

NS_ASSUME_NONNULL_END
