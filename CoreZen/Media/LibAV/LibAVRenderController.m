//
//  LibAVRenderController.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "LibAVRenderController.h"
#import "LibAVInfoController.h"
#import "WorkQueue.h"

@import Cocoa;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>

#pragma clang diagnostic pop

@interface ZENLibAVRenderController () {
	AVCodecContext *_codecContext;
}

@property (nonatomic, weak) ZENLibAVInfoController *infoController;

@property (nonatomic, strong) ZENWorkQueue *workQueue;

- (void)avInitWithCodec:(const AVCodec *)codec
				 stream:(const AVStream *)stream;

- (BOOL)renderRawFrame:(AVFrame *)frame
		 formatContext:(AVFormatContext *)formatContext
				stream:(const AVStream *)stream
			 timestamp:(int64_t)timestamp;

- (BOOL)resizeRawFrame:(AVFrame **)frame
			   maxSize:(NSSize)size;

- (NSImage *)convertRawFrameToImage:(AVFrame *)frame
						   rotation:(NSUInteger)rotation;

@end

@implementation ZENLibAVRenderController

// Leaves _codecContext NULL unless the decoder opened, so a non-NULL context
// always means frames can be decoded.
- (void)avInitWithCodec:(const AVCodec *)codec
				 stream:(const AVStream *)stream {
	if (!codec || !stream) {
		NSLog(@"avInitWithCodec: codec or stream is NULL");
		return;
	}
	AVCodecContext *codecContext = avcodec_alloc_context3(codec);
	if (!codecContext) {
		NSLog(@"avcodec_alloc_context3 failed");
		return;
	}
	avcodec_parameters_to_context(codecContext, stream->codecpar);

	if (codecContext->pix_fmt < 0 || codecContext->pix_fmt >= AV_PIX_FMT_NB) {
		NSLog(@"Video codec pixel format is invalid");
		avcodec_free_context(&codecContext);
		return;
	}

	// iina does this...
	codecContext->time_base = stream->time_base;

	int result = avcodec_open2(codecContext, codec, NULL);
	if (result < 0) {
		NSLog(@"avcodec_open2 failed, result: %d", result);
		avcodec_free_context(&codecContext);
		return;
	}

	_codecContext = codecContext;
}

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController {
	self = [super init];
	if (self) {
		_infoController = infoController;

		_workQueue = [ZENWorkQueue workQueue:@"ZENMediaFile.libav-render" qos:QOS_CLASS_USER_INITIATED];

		const AVCodec *videoCodec = infoController.videoCodecHandle;
		const AVStream *videoStream = infoController.videoStreamHandle;

		[self avInitWithCodec:videoCodec stream:videoStream];
	}
	return self;
}

- (void)terminate {
	// Waits for a render that's in progress to finish
	[self.workQueue terminate:^{}];

	if (_codecContext) {
		avcodec_free_context(&_codecContext);
	}
}

// Decodes the first frame from the keyframe at or before timestamp
- (BOOL)renderRawFrame:(AVFrame *)frame
		 formatContext:(AVFormatContext *)formatContext
				stream:(const AVStream *)stream
			 timestamp:(int64_t)timestamp {
	int streamIndex = stream->index;

	int result = av_seek_frame(formatContext, streamIndex, timestamp, AVSEEK_FLAG_BACKWARD);
	if (result < 0) {
		NSLog(@"av_seek_frame failed: %d", result);
		return NO;
	}

	// Drop what the decoder holds from the last render. This also resets a
	// decoder that was drained at the end of the file.
	avcodec_flush_buffers(_codecContext);

	AVPacket *packet = av_packet_alloc();
	if (!packet) {
		NSLog(@"av_packet_alloc failed");
		return NO;
	}

	// The decoder may hold frames back to put them in display order, so feed it
	// packets until it has a frame for us
	while ((result = avcodec_receive_frame(_codecContext, frame)) == AVERROR(EAGAIN)) {
		result = av_read_frame(formatContext, packet);
		if (result == AVERROR_EOF) {
			// Out of packets: an empty packet tells the decoder to output the
			// frames it's still holding, then report the end
			result = avcodec_send_packet(_codecContext, NULL);
		} else if (result >= 0) {
			if (packet->stream_index == streamIndex) {
				result = avcodec_send_packet(_codecContext, packet);
			}
			av_packet_unref(packet);
		}
		if (result < 0) {
			break;
		}
	}

	av_packet_free(&packet);

	// AVERROR_EOF only means the stream ended without another frame
	if (result < 0 && result != AVERROR_EOF) {
		NSLog(@"Decoding a frame failed: %d", result);
	}
	return (result >= 0);
}

- (BOOL)resizeRawFrame:(AVFrame **)frame
			   maxSize:(NSSize)maxSize {
	BOOL success = NO;
	AVFrame *rgbFrame = av_frame_alloc();

	// At the end, one frame will get freed and the other returned. If conversion
	// is successful, we'll update this to point to sourceFrame.
	AVFrame *frameToFree = rgbFrame;

	AVFrame *sourceFrame = *frame;

	NSSize sourceSize = NSMakeSize(sourceFrame->width, sourceFrame->height);

	if (sourceSize.width <= 0 || sourceSize.height <= 0) {
		av_frame_free(&rgbFrame);
		return NO;
	}

	double factorX = maxSize.width / sourceSize.width;
	double factorY = maxSize.height / sourceSize.height;
	double scaleFactor = fmin(factorX, factorY);

	double scaledX = round(sourceSize.width * scaleFactor);
	double scaledY = round(sourceSize.height * scaleFactor);

	rgbFrame->width = scaledX;
	rgbFrame->height = scaledY;
	rgbFrame->format = AV_PIX_FMT_RGBA;

	int result = av_frame_get_buffer(rgbFrame, 1);

	if (result >= 0) {
		// Cast to get around rules about adding `const` more than one level deep: https://stackoverflow.com/a/5055789
		const uint8_t *const *frameData = (const uint8_t *const *)sourceFrame->data;

		// Describe the source from the frame itself: its buffers have its size and
		// format, which needn't match what the codec context last reported
		struct SwsContext *scaleContext = sws_getContext(sourceFrame->width, sourceFrame->height, sourceFrame->format,
														 rgbFrame->width, rgbFrame->height, rgbFrame->format,
														 SWS_BILINEAR, NULL, NULL, NULL);
		if (scaleContext) {
			// Scale and convert colorspace to new frame
			result = sws_scale(scaleContext, frameData, sourceFrame->linesize, 0, sourceFrame->height,
							   rgbFrame->data, rgbFrame->linesize);
			sws_freeContext(scaleContext);
		} else {
			NSLog(@"sws_getContext failed for pixel format %d", sourceFrame->format);
			result = AVERROR(EINVAL);
		}

		if (result >= 0) {
			frameToFree = sourceFrame;
			*frame = rgbFrame;
			success = YES;

		} else {
			NSLog(@"sws_scale failed: %d", result);
		}
	} else {
		NSLog(@"av_frame_get_buffer failed: %d", result);
	}

	av_frame_free(&frameToFree);

	return success;
}

// image turned clockwise by rotation degrees, a multiple of 90
static CGImageRef ZENCreateRotatedImage(CGImageRef image, NSUInteger rotation) CF_RETURNS_RETAINED {
	size_t width = CGImageGetWidth(image);
	size_t height = CGImageGetHeight(image);
	BOOL quarterTurn = (rotation == 90 || rotation == 270);
	size_t rotatedWidth = quarterTurn ? height : width;
	size_t rotatedHeight = quarterTurn ? width : height;

	CGContextRef context = CGBitmapContextCreate(NULL, rotatedWidth, rotatedHeight, 8, 0, CGImageGetColorSpace(image),
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	if (!context) {
		return CGImageRetain(image);
	}
	// Turn about the center. Core Graphics' y axis points up, so clockwise on screen
	// is a negative angle. Quarter turns land every pixel on a pixel, so there's
	// nothing to smooth.
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	CGContextTranslateCTM(context, rotatedWidth / 2.0, rotatedHeight / 2.0);
	CGContextRotateCTM(context, -(CGFloat)rotation * M_PI / 180.0);
	CGContextDrawImage(context, CGRectMake(-(CGFloat)width / 2.0, -(CGFloat)height / 2.0, width, height), image);
	CGImageRef rotated = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	return rotated;
}

- (NSImage *)convertRawFrameToImage:(AVFrame *)frame
						   rotation:(NSUInteger)rotation {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

	void *frameData = frame->data[0];
	size_t width = frame->width;
	size_t height = frame->height;

	CGContextRef bitmapContext = CGBitmapContextCreate(frameData, width, height, 8, width * 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	// The image keeps its own copy of the pixels, so the context can go. Unlike
	// CFRelease, these release functions take NULL.
	CGImageRef bitmap = bitmapContext ? CGBitmapContextCreateImage(bitmapContext) : NULL;
	CGContextRelease(bitmapContext);
	CGColorSpaceRelease(colorSpace);

	if (bitmap && rotation != 0) {
		CGImageRef rotated = ZENCreateRotatedImage(bitmap, rotation);
		CGImageRelease(bitmap);
		bitmap = rotated;
	}
	if (!bitmap) {
		// Core Graphics couldn't make the image, so the frame has none
		return nil;
	}

	NSImage *image = [[NSImage alloc] initWithCGImage:bitmap size:NSZeroSize];
	CGImageRelease(bitmap);
	return image;
}

// Runs on the work queue. Leaves renderedFrame.image nil when there is nothing
// to render: no video stream (audio-only files), a file libav couldn't open, a
// decoder that didn't open, or an unknown duration.
- (void)renderFrameOnWorkQueue:(ZENRenderedFrame *)renderedFrame
						  size:(NSSize)size {
	ZENLibAVInfoController *infoController = self.infoController;

	double durationSeconds = infoController.durationSeconds;
	if (durationSeconds <= 0) {
		return;
	}

	if (renderedFrame.requestType == ZENFrameRequestTypeSeconds) {
		// seconds -> percentage
		renderedFrame.requestedPercentage = renderedFrame.requestedSeconds / durationSeconds;
	} else {
		// percentage -> seconds
		renderedFrame.requestedSeconds = durationSeconds * renderedFrame.requestedPercentage;
	}

	AVFormatContext *formatContext = infoController.formatContextHandle;
	const AVStream *stream = infoController.videoStreamHandle;
	if (!_codecContext || !formatContext || !stream) {
		return;
	}

	// Get duration in terms of the video stream time base (instead of overall libav time base)
	int64_t durationAVTicks = (int64_t)infoController.durationMicroseconds;
	int64_t durationStreamTicks = av_rescale_q(durationAVTicks, AV_TIME_BASE_Q, stream->time_base);
	if (durationStreamTicks <= 0) {
		return;
	}
	int64_t frameTimestamp = durationStreamTicks * renderedFrame.requestedPercentage;

	renderedFrame.requestedTimestamp = frameTimestamp;

	AVFrame *rawFrame = av_frame_alloc();

	// Render the frame at timestamp from media file
	if ([self renderRawFrame:rawFrame formatContext:formatContext stream:stream timestamp:frameTimestamp]) {
		renderedFrame.actualTimestamp = rawFrame->best_effort_timestamp;
		renderedFrame.actualPercentage = renderedFrame.actualTimestamp / (double)durationStreamTicks;
		renderedFrame.actualSeconds = renderedFrame.actualPercentage * durationSeconds;

		// The image is turned upright last, so a quarter turn means fitting the
		// stored frame into the box turned on its side
		NSUInteger rotation = infoController.rotationDegrees;
		NSSize frameSize = (rotation == 90 || rotation == 270) ? NSMakeSize(size.height, size.width) : size;

		// Resize the frame to desired size, convert to RGB
		if ([self resizeRawFrame:&rawFrame maxSize:frameSize]) {
			renderedFrame.image = [self convertRawFrameToImage:rawFrame rotation:rotation];
		}
	}

	av_frame_free(&rawFrame);
}

- (ZENWorkQueueToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
							  size:(NSSize)size
						completion:(ZENRenderFrameResultsBlock)completion {
	void (^complete)(void) = ^{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			completion(renderedFrame);
		});
	};

	ZENWorkQueueToken *token = [self.workQueue async:^(ZENWorkQueueToken *canceled) {
		if (!canceled.canceled) {
			[self renderFrameOnWorkQueue:renderedFrame size:size];
		}
		complete();
	}];

	if (!token) {
		// The work queue was terminated, so the block above will never run
		complete();
	}
	return token;
}

@end
