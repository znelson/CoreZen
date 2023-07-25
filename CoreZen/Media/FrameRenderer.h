//
//  FrameRenderer.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>

@class ZENRenderedFrame;
@class ZENWorkQueueToken;

// Completion block types
typedef void (^ZENRenderFrameResultsBlock)(ZENRenderedFrame *frame);
typedef void (^ZENRenderFramesResultsBlock)(NSArray<ZENRenderedFrame *> *frames);

// Rendered frame result
@interface ZENRenderedFrame : NSObject

// The rendered video frame image
@property (nonatomic, strong) NSImage *image;

// The requested position of the frame
@property (nonatomic) int64_t requestedTimestamp;
@property (nonatomic) double requestedSeconds;
@property (nonatomic) double requestedPercentage;

// The actual rendered position of the frame
@property (nonatomic) int64_t actualTimestamp;
@property (nonatomic) double actualSeconds;
@property (nonatomic) double actualPercentage;

@end

@class ZENMediaFile;
@protocol ZENFrameRenderController;

// Interface for requesting rendered frames
@interface ZENFrameRenderer : NSObject

@property (nonatomic, strong, readonly) ZENMediaFile *mediaFile;

+ (instancetype)frameRendererWithMediaFile:(ZENMediaFile *)mediaFile;

- (ZENWorkQueueToken *)renderFrameAtSeconds:(double)seconds
									  width:(NSUInteger)width
									 height:(NSUInteger)height
								 completion:(ZENRenderFrameResultsBlock)completion;

- (ZENWorkQueueToken *)renderFrameAtPercentage:(double)percentage
										 width:(NSUInteger)width
										height:(NSUInteger)height
									completion:(ZENRenderFrameResultsBlock)completion;

- (ZENWorkQueueToken *)renderFrames:(NSUInteger)count
							  width:(NSUInteger)width
							 height:(NSUInteger)height
						 completion:(ZENRenderFramesResultsBlock)completion;

@end
