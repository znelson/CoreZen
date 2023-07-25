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

@interface ZENLibAVRenderController ()
{
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

- (NSImage *)convertRawFrameToImage:(AVFrame *)frame;

@end

@implementation ZENLibAVRenderController

- (void)avInitWithCodec:(const AVCodec *)codec
				 stream:(const AVStream *)stream {
	_codecContext = avcodec_alloc_context3(codec);
	avcodec_parameters_to_context(_codecContext, stream->codecpar);
	
	if (_codecContext->pix_fmt < 0 || _codecContext->pix_fmt >= AV_PIX_FMT_NB) {
		NSLog(@"Video codec pixel format is invalid");
		return;
	}
	
	// iina does this...
	_codecContext->time_base = stream->time_base;
	
	int result = avcodec_open2(_codecContext, codec, NULL);
	if (result < 0) {
		NSLog(@"avcodec_open2 failed, result: %d", result);
		return;
	}
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
	NSLog(@"Terminating libav render queue...");
	[self.workQueue terminate:^{
		NSLog(@"Finished terminating libav render queue");
	}];
	
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
				if (result == AVERROR(EAGAIN)) {
					NSLog(@"avcodec_receive_frame failed: EAGAIN (input not ready, retrying)");
					continue;
				}
				
				if (result < 0) {
					NSLog(@"avcodec_receive_frame failed: %d", result);
				}
				break;
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
			   maxSize:(NSSize)maxSize {
	
	BOOL success = NO;
	AVFrame *rgbFrame = av_frame_alloc();
	
	// At the end, one frame will get freed and the other returned. If conversion
	// is successful, we'll update this to point to sourceFrame.
	AVFrame *frameToFree = rgbFrame;
	
	AVFrame *sourceFrame = *frame;
	
	NSSize sourceSize = NSMakeSize(sourceFrame->width, sourceFrame->height);
	
	if (sourceSize.width > 0 && sourceSize.height > 0) {
		
		double factorX = maxSize.width / sourceSize.width;
		double factorY = maxSize.height / sourceSize.height;
		double scaleFactor = fmin(factorX, factorY);
		
		double scaledX = round(sourceSize.width * scaleFactor);
		double scaledY = round(sourceSize.height * scaleFactor);
		
		rgbFrame->width = scaledX;
		rgbFrame->height = scaledY;
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
	}
	
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

- (ZENWorkQueueToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
							  size:(NSSize)size
						completion:(ZENRenderFrameResultsBlock)completion {
	
	return [self.workQueue async:^(ZENWorkQueueToken *canceled) {
		if (!canceled.canceled) {
			ZENLibAVInfoController *infoController = self.infoController;
			
			double durationSeconds = infoController.durationSeconds;
			
			// Calling code fills in either .requestedSeconds or .requestedPercentage; fill in the other
			if (renderedFrame.requestedSeconds > renderedFrame.requestedPercentage) {
				// seconds -> percentage
				renderedFrame.requestedPercentage = renderedFrame.requestedSeconds / durationSeconds;
			} else if (renderedFrame.requestedPercentage > renderedFrame.requestedSeconds) {
				// percentage -> seconds
				renderedFrame.requestedSeconds = durationSeconds * renderedFrame.requestedPercentage;
			}
			
			AVFormatContext *formatContext = infoController.formatContextHandle;
			const AVStream *stream = infoController.videoStreamHandle;
			
			int64_t durationAVTicks = formatContext->duration;
			
			// Get duration in terms of the video stream time base (instead of overall libav time base)
			int64_t durationStreamTicks = av_rescale_q(durationAVTicks, AV_TIME_BASE_Q, stream->time_base);
			int64_t frameTimestamp = durationStreamTicks * renderedFrame.requestedPercentage;
			
			renderedFrame.requestedTimestamp = frameTimestamp;
			
			AVFrame *rawFrame = av_frame_alloc();
			
			// Render the frame at timestamp from media file
			if ([self renderRawFrame:rawFrame formatContext:formatContext stream:stream timestamp:frameTimestamp]) {
				
				renderedFrame.actualTimestamp = rawFrame->best_effort_timestamp;
				renderedFrame.actualPercentage = renderedFrame.actualTimestamp / (double)durationStreamTicks;
				renderedFrame.actualSeconds = renderedFrame.actualPercentage * durationSeconds;
				
				// Resize the frame to desired size, convert to RGB
				if ([self resizeRawFrame:&rawFrame maxSize:size]) {
					renderedFrame.image = [self convertRawFrameToImage:rawFrame];
				}
			}
			
			av_frame_free(&rawFrame);
		}
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
			completion(renderedFrame);
		});
	}];
}

@end
