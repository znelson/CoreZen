//
//  LibAVRenderController.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "LibAVRenderController.h"
#import "LibAVInfoController.h"
#import "MediaFile.h"
#import "FrameRenderer.h"

@import Cocoa;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/imgutils.h>
#import <libswscale/swscale.h>

#pragma clang diagnostic pop

@interface ZENLibAVRenderController ()
{
	AVCodecContext *_codecContext;
}

@property (nonatomic, weak) ZENMediaFile *mediaFile;
@property (nonatomic, weak) ZENLibAVInfoController *infoController;

- (void)avInitWithCodec:(const AVCodec *)codec
				 stream:(const AVStream *)stream;

- (BOOL)renderRawFrame:(AVFrame *)frame
		 formatContext:(AVFormatContext *)formatContext
				stream:(const AVStream *)stream
			 timestamp:(int64_t)timestamp;

- (BOOL)resizeRawFrame:(AVFrame **)frame
					   size:(NSSize)size;

- (NSImage *)convertRawFrameToImage:(AVFrame *)frame;

@end

@implementation ZENLibAVRenderController

- (void)avInitWithCodec:(const AVCodec *)codec stream:(const AVStream *)stream {
	_codecContext = avcodec_alloc_context3(codec);
	avcodec_parameters_to_context(_codecContext, stream->codecpar);
	
	if (_codecContext->pix_fmt < 0 || _codecContext->pix_fmt >= AV_PIX_FMT_NB) {
		NSLog(@"Video codec pixel format is invalid (%@)", _mediaFile.fileURL);
		return;
	}
	
	// iina does this...
	_codecContext->time_base = stream->time_base;
	
	int result = avcodec_open2(_codecContext, codec, NULL);
	if (result < 0) {
		NSLog(@"avcodec_open2(%@) failed, result: %d", _mediaFile.fileURL, result);
		return;
	}
}

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController {
	self = [super init];
	if (self) {
		_mediaFile = infoController.mediaFile;
		_infoController = infoController;
		
		const AVCodec *videoCodec = infoController.videoCodecHandle;
		const AVStream *videoStream = infoController.videoStreamHandle;
		
		[self avInitWithCodec:videoCodec stream:videoStream];
	}
	return self;
}

- (void)terminate {
	if (_codecContext) {
		avcodec_free_context(&_codecContext);
	}
}

- (BOOL)renderRawFrame:(AVFrame *)frame
		 formatContext:(AVFormatContext *)formatContext
				stream:(const AVStream *)stream
			 timestamp:(int64_t)timestamp {
	
	avcodec_flush_buffers(_codecContext);
	
	int streamIndex = stream->index;
	
	int result = av_seek_frame(formatContext, streamIndex, timestamp, AVSEEK_FLAG_BACKWARD);
	if (result < 0) {
		NSLog(@"av_seek_frame failed: %d", result);
		return FALSE;
	}
	
	avcodec_flush_buffers(_codecContext);
	
	AVPacket packet;
	
	while (av_read_frame(formatContext, &packet) >= 0) {
		@try {
			if (packet.stream_index == streamIndex) {
				result = avcodec_send_packet(_codecContext, &packet);
				if (result < 0) {
					NSLog(@"avcodec_send_packet failed: %d", result);
					break;
				}
				
				result = avcodec_receive_frame(_codecContext, frame);
				if (result < 0) {
					if (result == AVERROR(EAGAIN)) {
						NSLog(@"avcodec_receive_frame failed: EAGAIN (input not ready, retrying)");
						continue;
					} else {
						NSLog(@"avcodec_receive_frame failed: %d", result);
						break;
					}
				}
			}
		} @catch (NSException *exception) {
			NSLog(@"Exception caught during decode: %@", exception);
		} @finally {
			av_packet_unref(&packet);
		}
	}
	
	return (result >= 0);
}

- (BOOL)resizeRawFrame:(AVFrame **)frame
				  size:(NSSize)size {
	
	BOOL success = NO;
	AVFrame *rgbFrame = av_frame_alloc();
	
	AVFrame *sourceFrame = *frame;
	
	// At the end, one frame will get freed and the other returned. If conversion
	// is successful, we'll update this to point to sourceFrame.
	AVFrame *frameToFree = rgbFrame;
	
	rgbFrame->width = size.width;
	rgbFrame->height = size.height;
	rgbFrame->format = AV_PIX_FMT_RGBA;
	
	int bufferSize = av_image_get_buffer_size(rgbFrame->format, rgbFrame->width, rgbFrame->height, 1);
	
	uint8_t *rgbBuffer = av_malloc(bufferSize);
	
	int result = av_image_fill_arrays(rgbFrame->data, rgbFrame->linesize, rgbBuffer, rgbFrame->format, rgbFrame->width, rgbFrame->height, 1);
	
	av_free(rgbBuffer);
	
	if (result >= 0) {
		// Cast to get around rules about adding `const` more than one level deep: https://stackoverflow.com/a/5055789
		const uint8_t * const * frameData = (const uint8_t * const *)sourceFrame->data;
		
		// Create scale context
		struct SwsContext *scaleContext = sws_getContext(_codecContext->width, _codecContext->height, _codecContext->pix_fmt, rgbFrame->width, rgbFrame->height, rgbFrame->format, SWS_BILINEAR, NULL, NULL, NULL);
		
		// Scale and convert colorspace to new frame
		result = sws_scale(scaleContext, frameData, sourceFrame->linesize, 0, _codecContext->height, rgbFrame->data, rgbFrame->linesize);
		
		// Clean up scale context
		sws_freeContext(scaleContext);
		
		if (result >= 0) {
			frameToFree = sourceFrame;
			*frame = rgbFrame;
			success = YES;

		} else {
			NSLog(@"sws_scale failed: %d", result);
		}
	} else {
		NSLog(@"av_image_fill_arrays failed: %d", result);
	}
	
	av_frame_free(&frameToFree);
	
	return success;
}

- (NSImage *)convertRawFrameToImage:(AVFrame *)frame {
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
	void *frameData = frame->data[0];
	size_t width = frame->width;
	size_t height = frame->height;
	
	CGContextRef bitmapContext = CGBitmapContextCreate(frameData, width, height, 8, width * 4, colorSpace, kCGImageAlphaPremultipliedLast);
	
	CGImageRef bitmap = CGBitmapContextCreateImage(bitmapContext);
	
	NSImage *image = [[NSImage alloc] initWithCGImage:bitmap size:NSZeroSize];
	
	CFRelease(colorSpace);
	CFRelease(bitmapContext);
	CFRelease(bitmap);
	
	return image;
}

- (void)renderFrame:(ZENRenderedFrame *)frame
			   size:(NSSize)size
		 completion:(ZENFrameRendererResultsBlock)completion {
	
	NSObject<ZENMediaInfoController> *infoController = self.infoController;
	
	double durationSeconds = infoController.durationSeconds;
	
	// Calling code fills in either .requestedSeconds or .requestedPercentage; fill in the other
	if (frame.requestedSeconds > frame.requestedPercentage) {
		// seconds -> percentage
		frame.requestedPercentage = frame.requestedSeconds / durationSeconds;
	} else if (frame.requestedPercentage > frame.requestedSeconds) {
		// percentage -> seconds
		frame.requestedSeconds = durationSeconds * frame.requestedPercentage;
	}
	
	AVFormatContext *formatContext = infoController.formatContextHandle;
	const AVStream *stream = infoController.videoStreamHandle;
	
	int64_t durationTicks = formatContext->duration;
	
	// Get duration in terms of the video stream time base (instead of overall libav time base)
	int64_t duration = av_rescale_q(durationTicks, AV_TIME_BASE_Q, stream->time_base);
	int64_t frameTimestamp = duration * frame.requestedPercentage;
	
	frame.requestedTimestamp = frameTimestamp;
	
	AVFrame *rawFrame = av_frame_alloc();
	
	// Render the frame at timestamp from media file
	if ([self renderRawFrame:rawFrame formatContext:formatContext stream:stream timestamp:frameTimestamp]) {
		
		frame.actualTimestamp = rawFrame->best_effort_timestamp;
		frame.actualPercentage = frame.actualTimestamp / (double)durationTicks;
		frame.actualSeconds = frame.actualPercentage * durationSeconds;
		
		// Resize the frame to desired size, convert to RGB
		if ([self resizeRawFrame:&rawFrame size:size]) {
			
			frame.image = [self convertRawFrameToImage:rawFrame];
		}
	}
	
	av_frame_free(&rawFrame);
	
	completion(frame);
}

@end
