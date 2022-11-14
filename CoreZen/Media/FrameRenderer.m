//
//  FrameRenderer.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "FrameRenderer+Private.h"
#import "FrameRenderController.h"

@implementation ZENRenderedFrame
@end

@implementation ZENFrameRenderer

- (instancetype)initWithController:(NSObject<ZENFrameRenderController> *)controller
						 mediaFile:(ZENMediaFile *)mediaFile {
	self = [super init];
	if (self) {
		_frameRenderController = controller;
		_mediaFile = mediaFile;
	}
	return self;
}

- (void)renderFrameAtSeconds:(double)seconds
					   width:(NSUInteger)width
					  height:(NSUInteger)height
				  completion:(ZENFrameRendererResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedSeconds = seconds;
	
	[self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

- (void)renderFrameAtPercentage:(double)percentage
						  width:(NSUInteger)width
						 height:(NSUInteger)height
					 completion:(ZENFrameRendererResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedPercentage = percentage;
	
	[self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

@end
