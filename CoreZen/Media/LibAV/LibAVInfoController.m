//
//  LibAVInfoController.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "LibAVInfoController.h"
#import "LibAVRenderController.h"

#import <stdatomic.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>
#import <libavutil/display.h>

#pragma clang diagnostic pop

void ZENLogAVFindBestStreamError(NSString *filePath, int returnCode, enum AVMediaType mediaType) {
	const char *streamType = av_get_media_type_string(mediaType);
	char reason[AV_ERROR_MAX_STRING_SIZE];
	av_strerror(returnCode, reason, sizeof(reason));
	NSLog(@"av_find_best_stream(%@, %s) failed: %s", filePath, streamType ? streamType : "unknown", reason);
}

// A codec's name as a string, or nil if the codec or its name is missing
static NSString *ZENCodecName(const AVCodec *codec, BOOL longName) {
	if (!codec) {
		return nil;
	}
	const char *name = longName ? codec->long_name : codec->name;
	return name ? @(name) : nil;
}

@interface ZENLibAVInfoController () {
	AVFormatContext *_formatContext;

	// Video
	const AVCodec *_videoCodec;
	const AVStream *_videoStream;

	// Audio
	const AVCodec *_audioCodec;
	const AVStream *_audioStream;
}

@property (nonatomic, strong) ZENLibAVRenderController *renderController;

- (void)avInit:(NSString *)filePath;

@end

@implementation ZENLibAVInfoController

@synthesize identifier = _identifier;

- (void)avInit:(NSString *)mediaPath {
	_formatContext = avformat_alloc_context();

	// avformat_open_input() documentation:
	// Returns 0 on success, a negative AVERROR on failure.
	int result = avformat_open_input(&_formatContext, mediaPath.fileSystemRepresentation, NULL, NULL);
	if (result == 0) {
		// avformat_find_stream_info() documentation:
		// Returns >=0 if OK, AVERROR_xxx on error
		result = avformat_find_stream_info(_formatContext, NULL);
		if (result >= 0) {
			const int videoStreamIndex = av_find_best_stream(_formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &_videoCodec, 0);
			if (videoStreamIndex > -1) {
				// av_find_best_stream() documentation:
				// If av_find_best_stream returns successfully and decoder_ret (&_videoCodec) is not NULL,
				// then *decoder_ret (_videoCodec) is guaranteed to be set to a valid AVCodec.

				_videoStream = _formatContext->streams[videoStreamIndex];
			} else {
				ZENLogAVFindBestStreamError(mediaPath, videoStreamIndex, AVMEDIA_TYPE_VIDEO);
			}

			const int audioStreamIndex = av_find_best_stream(_formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &_audioCodec, 0);
			if (audioStreamIndex > -1) {
				_audioStream = _formatContext->streams[audioStreamIndex];
			} else if (audioStreamIndex != AVERROR_STREAM_NOT_FOUND) {
				// A video with no sound has no audio stream, which isn't a failure
				ZENLogAVFindBestStreamError(mediaPath, audioStreamIndex, AVMEDIA_TYPE_AUDIO);
			}
		} else {
			NSLog(@"avformat_find_stream_info(%@) failed, result: %d", mediaPath, result);
		}
	} else {
		// avformat_open_input() documentation:
		// Note that a user-supplied AVFormatContext will be freed on failure.
		_formatContext = NULL;
		NSLog(@"avformat_open_input(%@) failed, result: %d", mediaPath, result);
	}
}

- (instancetype)initWithMediaPath:(NSString *)mediaPath {
	self = [super init];
	if (self) {
		static atomic_uint_fast64_t nextIdentifier = 0;
		_identifier = atomic_fetch_add(&nextIdentifier, 1);

		[self avInit:mediaPath];
	}
	return self;
}

- (AVFormatContext *)formatContextHandle {
	return _formatContext;
}

- (const AVCodec *)videoCodecHandle {
	return _videoCodec;
}

- (const AVStream *)videoStreamHandle {
	return _videoStream;
}

- (void)terminate {
	if (self.renderController) {
		[self.renderController terminate];
	}
	if (_formatContext) {
		avformat_close_input(&_formatContext);
	}
}

- (ZENLibAVRenderController *)frameRenderController {
	if (!self.renderController) {
		self.renderController = [[ZENLibAVRenderController alloc] initWithInfoController:self];
	}
	return self.renderController;
}

- (NSUInteger)durationMicroseconds {
	NSAssert(AV_TIME_BASE == 1000000, @"Expected libav AV_TIME_BASE 1000000 for microseconds, instead = %d", AV_TIME_BASE);
	if (!_formatContext || _formatContext->duration < 0) {
		return 0;
	}
	return (NSUInteger)_formatContext->duration;
}

- (double)durationSeconds {
	NSUInteger us = self.durationMicroseconds;
	return us / (double)AV_TIME_BASE;
}

- (NSUInteger)frameWidth {
	NSUInteger width = 0;
	if (_videoStream) {
		width = ((NSUInteger)_videoStream->codecpar->width);
	}
	return width;
}

- (NSUInteger)frameHeight {
	NSUInteger height = 0;
	if (_videoStream) {
		height = ((NSUInteger)_videoStream->codecpar->height);
	}
	return height;
}

- (double)pixelAspectRatio {
	if (!_videoStream) {
		return 1.0;
	}
	// The container's ratio if it has one, else the codec's. 0:1 means unknown.
	AVRational ratio = av_guess_sample_aspect_ratio(_formatContext, (AVStream *)_videoStream, NULL);
	return (ratio.num > 0 && ratio.den > 0) ? av_q2d(ratio) : 1.0;
}

- (NSUInteger)rotationDegrees {
	if (!_videoStream) {
		return 0;
	}
	const AVCodecParameters *parameters = _videoStream->codecpar;
	const AVPacketSideData *sideData = av_packet_side_data_get(parameters->coded_side_data, parameters->nb_coded_side_data,
															   AV_PKT_DATA_DISPLAYMATRIX);
	if (!sideData || sideData->size < 9 * sizeof(int32_t)) {
		return 0;
	}
	// FFmpeg gives the angle counterclockwise, from -180 to 180, or NaN for a
	// matrix that can't be undone. A matrix can also mirror the picture, which
	// this leaves out, as it does angles between quarter turns: both are rare.
	double counterclockwise = av_display_rotation_get((const int32_t *)sideData->data);
	if (isnan(counterclockwise)) {
		return 0;
	}
	long quarterTurns = lround(-counterclockwise / 90.0);
	return (NSUInteger)(((quarterTurns % 4) + 4) % 4) * 90;
}

- (NSString *)videoCodecName {
	return ZENCodecName(_videoCodec, NO);
}

- (NSString *)audioCodecName {
	return ZENCodecName(_audioCodec, NO);
}

- (NSString *)videoCodecLongName {
	return ZENCodecName(_videoCodec, YES);
}

- (NSString *)audioCodecLongName {
	return ZENCodecName(_audioCodec, YES);
}

@end
