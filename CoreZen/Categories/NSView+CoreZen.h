//
//  NSView+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 11/15/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSView (CoreZen)

/// Adds constraints that make a subview fill this view.
///
/// They tie the subview's left and top edges, width and height to this view's.
/// The subview's autoresizing mask would add constraints that conflict with
/// these, so a subview made in code needs
/// `translatesAutoresizingMaskIntoConstraints` set to NO.
- (void)zen_addConstraintsForEqualSizes:(NSView *)other;

@end

NS_ASSUME_NONNULL_END
