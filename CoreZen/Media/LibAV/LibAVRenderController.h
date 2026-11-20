//
//  LibAVRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRenderer.h>

@class ZENLibAVInfoController;
@class ZENWorkQueueToken;

@interface ZENLibAVRenderController : NSObject

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController;

- (void)terminate;

// With exact NO, renders the keyframe at or before the frame's requested time;
// with YES, the first frame at or after it
- (ZENWorkQueueToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
							  size:(NSSize)size
							 exact:(BOOL)exact
						completion:(ZENRenderFrameResultsBlock)completion;

@end
