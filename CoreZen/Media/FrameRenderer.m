//
//  FrameRenderer.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "FrameRenderer+Private.h"
#import "FrameCollector.h"
#import "LibAVRenderController.h"
#import "WorkQueue+Private.h"

@implementation ZENRenderedFrame
@end

@implementation ZENFrameRenderer

- (instancetype)initWithController:(ZENLibAVRenderController *)controller
						 mediaFile:(ZENMediaFile *)mediaFile {
	self = [super init];
	if (self) {
		_frameRenderController = controller;
		_mediaFile = mediaFile;
	}
	return self;
}

- (ZENWorkQueueToken *)renderFrameAtSeconds:(double)seconds
									  width:(NSUInteger)width
									 height:(NSUInteger)height
								 completion:(ZENRenderFrameResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedSeconds = seconds;
	
	return [self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

- (ZENWorkQueueToken *)renderFrameAtPercentage:(double)percentage
										 width:(NSUInteger)width
										height:(NSUInteger)height
									completion:(ZENRenderFrameResultsBlock)completion {
	
	ZENRenderedFrame *frame = [ZENRenderedFrame new];
	frame.requestedPercentage = percentage;
	
	return [self.frameRenderController renderFrame:frame size:NSMakeSize(width, height) completion:completion];
}

- (ZENWorkQueueToken *)renderFrames:(NSUInteger)count
							  width:(NSUInteger)width
							 height:(NSUInteger)height
						 completion:(ZENRenderFramesResultsBlock)completion {
	ZENWorkQueueToken *result = nil;
	if (count >= 2) {
		ZENFrameCollector *collector = [ZENFrameCollector frameCollectorWithCount:count completion:completion];
		NSMutableArray<ZENWorkQueueToken *> *tokens = [NSMutableArray new];
		double denominator = count - 1;
		
		for (NSUInteger index = 0; index < count; ++index) {
			double percentage = index / denominator;
			
			ZENWorkQueueToken *token = [self renderFrameAtPercentage:percentage
															width:width
														   height:height
													   completion:^(ZENRenderedFrame *frame) {
				[collector collect:frame];
			}];
			
			[tokens addObject:token];
		}
		
		result = [[ZENWorkQueueMultiToken alloc] initWithTokens:tokens];
		
	} else if (count == 1) {
		result = [self renderFrameAtPercentage:0.50 width:width height:height completion:^(ZENRenderedFrame *frame) {
			NSArray *frames = @[frame];
			completion(frames);
		}];
	}
	return result;
}

@end
