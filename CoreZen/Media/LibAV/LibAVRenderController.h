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

@property (nonatomic, weak, readonly) ZENMediaFile *mediaFile;

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController;

// ZENFrameRenderController protocol

- (void)terminate;

- (void)renderFrame:(ZENRenderedFrame *)frame
			   size:(NSSize)size
		 completion:(ZENFrameRendererResultsBlock)completion;

@end
