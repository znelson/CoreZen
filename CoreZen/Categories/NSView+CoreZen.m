//
//  NSView+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 11/15/22.
//

#import "NSView+CoreZen.h"

@implementation NSView (CoreZen)

- (void)zen_addConstraintsForEqualSizes:(NSView *)subView {
	NSMutableArray *constraints = [NSMutableArray new];
	
	NSLayoutAttribute attrs[4] = { NSLayoutAttributeLeft, NSLayoutAttributeTop, NSLayoutAttributeHeight, NSLayoutAttributeWidth };
	
	for (int i = 0; i < 4; ++i) {
		NSLayoutAttribute attr = attrs[i];
		NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:subView attribute:attr relatedBy:NSLayoutRelationEqual toItem:self attribute:attr multiplier:1 constant:0];
		[constraints addObject:constraint];
	}
	
	[self addConstraints:constraints];
}

@end
