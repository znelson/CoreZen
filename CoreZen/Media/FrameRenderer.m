//
//  FrameRenderer.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "FrameRenderer+Private.h"
#import "FrameRenderController.h"
#import "WorkQueue+Private.h"

@implementation ZENRenderedFrame
@end

@interface ZENRenderedFrameCollector : NSObject

@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, strong, readonly) ZENRenderFramesResultsBlock completion;
@property (nonatomic, strong, readonly) NSMutableArray<ZENRenderedFrame *> *frames;
@property (nonatomic, strong, readonly) NSLock *lock;

- (instancetype)initWithCount:(NSUInteger)count
				   completion:(ZENRenderFramesResultsBlock)completion;

- (void)collect:(ZENRenderedFrame *)frame;

@end

@implementation ZENRenderedFrameCollector

- (instancetype)initWithCount:(NSUInteger)count
				   completion:(ZENRenderFramesResultsBlock)completion {
	self = [super init];
	if (self) {
		_count = count;
		_completion = completion;
		_frames = [NSMutableArray new];
		_lock = [NSLock new];
	}
	return self;
}

- (void)collect:(ZENRenderedFrame *)frame {
	NSArray<ZENRenderedFrame *> *result = nil;
	
	[self.lock lock];
	
	[self.frames addObject:frame];
	if (self.frames.count == self.count) {
		result = self.frames;
	}

	[self.lock unlock];
	
	if (result) {
		self.completion(result);
	}
}

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

- (ZENCancelToken *)renderFrames:(NSUInteger)count
						   width:(NSUInteger)width
						  height:(NSUInteger)height
					  completion:(ZENRenderFramesResultsBlock)completion {
	ZENCancelToken *result = nil;
	if (count > 2) {
		NSUInteger denominator = (count - 1);
		ZENRenderedFrameCollector *collector = [[ZENRenderedFrameCollector alloc] initWithCount:count completion:completion];
		NSMutableArray<ZENWorkQueueToken *> *tokens = [NSMutableArray new];
		
		for (NSUInteger index = 0; index < count; ++index) {
			double percentage = index / denominator;
			
			// Scale to 1% to 99% range
			const double kBufferPercentage = 0.01;
			const double kScaledPercentage = 1.00 - (2 * kBufferPercentage);
			percentage = (percentage * kScaledPercentage) + kBufferPercentage;
			
			ZENCancelToken *token = [self renderFrameAtPercentage:percentage
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
