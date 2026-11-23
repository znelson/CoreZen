//
//  ArchivedView.h
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// The methods of a view that loads its contents from a nib.
@protocol ZENArchivedView

/// The name of the nib the view loads its contents from.
///
/// A subclass must override it. The nib is in the bundle that contains the
/// subclass.
- (NSString *)archivedViewName;

/// Loads the view's nib, and fills the view with the nib's root view.
///
/// Both `initWithFrame:` and `initWithCoder:` call it. A subclass can override
/// it to finish setting up, calling super first.
- (void)setupCommon;

/// The view from the nib that fills this view.
///
/// The view is the nib's owner, so in Interface Builder, connect this outlet of
/// the File's Owner to the nib's top-level view.
@property (nonatomic, strong, nullable) IBOutlet NSView *rootView;

@end

/// A view that loads its contents from a nib its subclass names.
///
/// A subclass names the nib with ``ZENArchivedView-c.protocol/archivedViewName``,
/// and the nib's top-level view fills the view.
@interface ZENArchivedView : NSView <ZENArchivedView>

/// Loads the view's nib, and fills the view with the nib's root view.
///
/// Both `initWithFrame:` and `initWithCoder:` call it. A subclass can override
/// it to finish setting up, calling super first.
- (void)setupCommon;

/// The view from the nib that fills this view.
///
/// The view is the nib's owner, so in Interface Builder, connect this outlet of
/// the File's Owner to the nib's top-level view.
@property (nonatomic, strong, nullable) IBOutlet NSView *rootView;

@end

NS_ASSUME_NONNULL_END
