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

/// A block called with one rendered frame.
typedef void (^ZENRenderFrameResultsBlock)(ZENRenderedFrame *frame);

/// A block called with several rendered frames.
typedef void (^ZENRenderFramesResultsBlock)(NSArray<ZENRenderedFrame *> *frames);

/// How a frame's position was asked for.
typedef NS_ENUM(NSInteger, ZENFrameRequestType) {
	/// As a time in seconds from the start of the file.
	ZENFrameRequestTypeSeconds,
	/// As a fraction of the file's duration, from 0 to 1.
	ZENFrameRequestTypePercentage
};

/// A frame rendered from a media file, with the position it was asked for and
/// the position it came from.
///
/// Most renders show the keyframe at or before the position asked for, which is
/// fast, so the frame can come from earlier.
/// ``ZENFrameRenderer/renderExactFrameAtSeconds:width:height:completion:``
/// shows the frame at the position instead.
///
/// Each position is given three ways: in seconds, counted from the start of the
/// file as a player counts them; as a fraction of the duration, from 0 to 1,
/// despite the name "percentage"; and as a timestamp, in the units of the video
/// stream's time base. Timestamps are the stream's own, which don't always start
/// at 0: in an MPEG transport stream, they usually start a second or so in. A
/// position the renderer couldn't work out, such as for a file it couldn't open,
/// is 0.
@interface ZENRenderedFrame : NSObject

/// The frame's image, or nil if it couldn't be rendered.
///
/// It fits within the width and height asked for, in the shape the video is
/// shown in: stretched to its pixel aspect ratio and turned upright.
@property (nonatomic, strong, nullable) NSImage *image;

/// Whether the frame was asked for by time or by fraction of the duration.
@property (nonatomic) ZENFrameRequestType requestType;

/// The position asked for, as a timestamp in the video stream's time base.
@property (nonatomic) int64_t requestedTimestamp;

/// The position asked for, in seconds.
@property (nonatomic) double requestedSeconds;

/// The position asked for, as a fraction of the duration from 0 to 1.
@property (nonatomic) double requestedPercentage;

/// The position of the frame rendered, as a timestamp in the video stream's
/// time base.
@property (nonatomic) int64_t actualTimestamp;

/// The position of the frame rendered, in seconds.
@property (nonatomic) double actualSeconds;

/// The position of the frame rendered, as a fraction of the duration from 0
/// to 1.
@property (nonatomic) double actualPercentage;

@end

@class ZENMediaFile;
@protocol ZENFrameRenderController;

/// Renders a media file's frames as images, for thumbnails and posters.
///
/// Renders run one at a time, in the order they're asked for. Every render
/// method calls its completion exactly once, on a background queue. A frame's
/// image is nil when it couldn't be rendered: the file has no video stream or
/// couldn't be opened, the render was canceled, or the media file was
/// terminated.
@interface ZENFrameRenderer : NSObject

/// The media file the renderer renders frames from.
@property (nonatomic, strong, readonly) ZENMediaFile *mediaFile;

/// Makes a renderer for a media file's frames.
+ (instancetype)frameRendererWithMediaFile:(ZENMediaFile *)mediaFile;

/// Renders the keyframe at or before a time in seconds, at most a width and
/// height in pixels.
///
/// A keyframe is quick to render, but can be as far before the time as the
/// video's keyframes are apart, often a few seconds. For the frame a player
/// shows at the time, use ``renderExactFrameAtSeconds:width:height:completion:``.
///
/// It returns a token to cancel the render with, or nil if there's nothing to
/// cancel because the media file was terminated already. The completion is
/// called either way.
- (nullable ZENWorkQueueToken *)renderFrameAtSeconds:(double)seconds
											   width:(NSUInteger)width
											  height:(NSUInteger)height
										  completion:(ZENRenderFrameResultsBlock)completion;

/// Renders the frame a player shows at a time in seconds, at most a width and
/// height in pixels.
///
/// That's the first frame at or after the time, as a player shows after seeking
/// there, or the last frame if the time is past it. Given a player's position,
/// such as ``ZENMediaPlayer/positionSeconds``, it's the frame the player is
/// showing. It's slower than ``renderFrameAtSeconds:width:height:completion:``,
/// since it decodes every frame from the keyframe before the time up to it.
///
/// It returns a token to cancel the render with, or nil if there's nothing to
/// cancel because the media file was terminated already. The completion is
/// called either way.
- (nullable ZENWorkQueueToken *)renderExactFrameAtSeconds:(double)seconds
													width:(NSUInteger)width
												   height:(NSUInteger)height
											   completion:(ZENRenderFrameResultsBlock)completion;

/// Renders the keyframe at or before a fraction of the duration, from 0 to 1,
/// at most a width and height in pixels.
///
/// Like ``renderFrameAtSeconds:width:height:completion:``, the keyframe can be
/// a few seconds before the position.
///
/// It returns a token to cancel the render with, or nil if there's nothing to
/// cancel because the media file was terminated already. The completion is
/// called either way.
- (nullable ZENWorkQueueToken *)renderFrameAtPercentage:(double)percentage
												  width:(NSUInteger)width
												 height:(NSUInteger)height
											 completion:(ZENRenderFrameResultsBlock)completion;

/// Renders keyframes spread evenly across the file, each at most a width and
/// height in pixels.
///
/// The frames go from the start of the file, at 0, to its end, at 1, and a
/// single frame comes from the middle. The completion gets the frames that
/// have an image, in order. It returns a token that cancels the renders not
/// yet run. It's nil when the count is 0, and can be nil when the media file
/// was terminated already. The completion is called either way.
- (nullable ZENWorkQueueToken *)renderFrames:(NSUInteger)count
									   width:(NSUInteger)width
									  height:(NSUInteger)height
								  completion:(ZENRenderFramesResultsBlock)completion;

@end

NS_ASSUME_NONNULL_END
