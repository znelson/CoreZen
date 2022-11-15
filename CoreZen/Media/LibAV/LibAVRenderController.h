//
//  LibAVRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRenderController.h>

@class ZENMediaFile;
@class ZENLibAVInfoController;

@interface ZENLibAVRenderController : NSObject <ZENFrameRenderController>

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController;

// ZENFrameRenderController protocol

- (void)terminate;

- (ZENCancelToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
						   size:(NSSize)size
					 completion:(ZENRenderFrameResultsBlock)completion;

@end
