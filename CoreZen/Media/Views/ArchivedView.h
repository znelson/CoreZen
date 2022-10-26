//
//  ArchivedView.h
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import <Cocoa/Cocoa.h>

@protocol ZENArchivedView

// Specifies the nib name - derived views MUST override
- (NSString *)archivedViewName;

// Common init path for both -initWithFrame and -initWithCoder - derived
// view may override, just be sure to call this super impl first
- (void)initCommon;

// rootView should be connected to the nib custom view in Interface Builder
@property (nonatomic, weak) IBOutlet NSView *rootView;

@end

@interface ZENArchivedView : NSView <ZENArchivedView>

- (void)initCommon;

@property (nonatomic, weak) IBOutlet NSView *rootView;

@end
