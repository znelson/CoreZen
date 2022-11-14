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

- (ZENCancelToken *)renderFrameAtSeconds:(double)seconds
								   width:(NSUInteger)width
								  height:(NSUInteger)height
							  completion:(ZENRenderFrameResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedSeconds = seconds;
	
	return [self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

- (ZENCancelToken *)renderFrameAtPercentage:(double)percentage
									  width:(NSUInteger)width
									 height:(NSUInteger)height
								 completion:(ZENRenderFrameResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedPercentage = percentage;
	
	return [self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

@end
