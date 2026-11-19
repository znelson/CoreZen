//
//  FrameRenderer.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>

@class ZENRenderedFrame;
@class ZENWorkQueueToken;

NS_ASSUME_NONNULL_BEGIN

// Completion block types
typedef void (^ZENRenderFrameResultsBlock)(ZENRenderedFrame *frame);
typedef void (^ZENRenderFramesResultsBlock)(NSArray<ZENRenderedFrame *> *frames);

typedef NS_ENUM(NSInteger, ZENFrameRequestType) {
	ZENFrameRequestTypeSeconds,
	ZENFrameRequestTypePercentage
};

// Rendered frame result
@interface ZENRenderedFrame : NSObject

// The rendered video frame image
@property (nonatomic, strong, nullable) NSImage *image;

// The requested position of the frame
@property (nonatomic) ZENFrameRequestType requestType;
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
//
// Every render method calls its completion exactly once, on a background queue.
// A frame's image is nil when it couldn't be rendered: the file has no video
// stream or couldn't be opened, the request was canceled, or the media file was
// terminated. renderFrames: only returns frames that have an image.
@interface ZENFrameRenderer : NSObject

@property (nonatomic, strong, readonly) ZENMediaFile *mediaFile;

+ (instancetype)frameRendererWithMediaFile:(ZENMediaFile *)mediaFile;

// Each returns a token to cancel the render with, or nil if there's nothing to
// cancel: the media file was already terminated, or renderFrames: was asked for
// no frames. The completion is called either way.
- (nullable ZENWorkQueueToken *)renderFrameAtSeconds:(double)seconds
											   width:(NSUInteger)width
											  height:(NSUInteger)height
										  completion:(ZENRenderFrameResultsBlock)completion;

- (nullable ZENWorkQueueToken *)renderFrameAtPercentage:(double)percentage
												  width:(NSUInteger)width
												 height:(NSUInteger)height
											 completion:(ZENRenderFrameResultsBlock)completion;

- (nullable ZENWorkQueueToken *)renderFrames:(NSUInteger)count
									   width:(NSUInteger)width
									  height:(NSUInteger)height
								  completion:(ZENRenderFramesResultsBlock)completion;

@end

NS_ASSUME_NONNULL_END
