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

- (ZENWorkQueueToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
							  size:(NSSize)size
						completion:(ZENRenderFrameResultsBlock)completion;

@end
