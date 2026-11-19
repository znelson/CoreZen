//
//  ArchivedView.h
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZENArchivedView

// Specifies the nib name - derived views MUST override
- (NSString *)archivedViewName;

// Common init path for both -initWithFrame and -initWithCoder - derived
// view may override, just be sure to call this super impl first
- (void)setupCommon;

// rootView should be connected to the nib custom view in Interface Builder
@property (nonatomic, strong, nullable) IBOutlet NSView *rootView;

@end

@interface ZENArchivedView : NSView <ZENArchivedView>

- (void)setupCommon;

@property (nonatomic, strong, nullable) IBOutlet NSView *rootView;

@end

NS_ASSUME_NONNULL_END
