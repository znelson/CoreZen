//
//  LibAVInfoController.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "LibAVInfoController.h"
#import "LibAVRenderController.h"
#import "MediaFile.h"

#import <stdatomic.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

#pragma clang diagnostic pop

void ZENLogAVFindBestStreamError(NSString *filePath, int returnCode, enum AVMediaType mediaType) {
	NSString *reason = @"Unknown";
	if (returnCode == AVERROR_STREAM_NOT_FOUND) {
		NSString *streamType = @"Unknown";
		if (mediaType == AVMEDIA_TYPE_VIDEO) {
			streamType = @"AVMEDIA_TYPE_VIDEO";
		} else if (mediaType == AVMEDIA_TYPE_AUDIO) {
			streamType = @"AVMEDIA_TYPE_AUDIO";
		}
		reason = [NSString stringWithFormat:@"No stream with the requested type could be found (%@)", streamType];
	}
	NSLog(@"avformat_find_stream_info(%@, AVMEDIA_TYPE_VIDEO) failed: %@", filePath, reason);
}

@interface ZENLibAVInfoController ()
{
	AVFormatContext *_formatContext;

	// Video
	const AVCodec *_videoCodec;
	const AVStream *_videoStream;

	// Audio
	const AVCodec *_audioCodec;
	const AVStream *_audioStream;
}

@property (nonatomic, weak) ZENMediaFile *mediaFile;

@property (nonatomic, strong) ZENLibAVRenderController *renderer;

- (void)avInit:(NSString *)filePath;

@end

@implementation ZENLibAVInfoController

@synthesize identifier=_identifier;

- (void)avInit:(NSString *)filePath {
	_formatContext = avformat_alloc_context();
	
	// avformat_open_input() documentation:
	// Returns 0 on success, a negative AVERROR on failure.
	int result = avformat_open_input(&_formatContext, filePath.fileSystemRepresentation, NULL, NULL);
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
				ZENLogAVFindBestStreamError(filePath, videoStreamIndex, AVMEDIA_TYPE_VIDEO);
			}
			
			const int audioStreamIndex = av_find_best_stream(_formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &_audioCodec, 0);
			if (audioStreamIndex > -1) {
				_audioStream = _formatContext->streams[audioStreamIndex];
			} else {
				ZENLogAVFindBestStreamError(filePath, audioStreamIndex, AVMEDIA_TYPE_AUDIO);
			}
		} else {
			NSLog(@"avformat_find_stream_info(%@) failed, result: %d", filePath, result);
		}
	} else {
		// avformat_open_input() documentation:
		// Note that a user-supplied AVFormatContext will be freed on failure.
		_formatContext = NULL;
		NSLog(@"avformat_open_input(%@) failed, result: %d", filePath, result);
	}
}

- (instancetype)initWithMediaFile:(ZENMediaFile *)mediaFile {
	self = [super init];
	if (self) {
		_mediaFile = mediaFile;
		
		static atomic_uint_fast64_t nextIdentifier = 0;
		_identifier = atomic_fetch_add(&nextIdentifier, 1);
		
		NSString *filePath = mediaFile.fileURL.path;
		[self avInit:filePath];
	}
	return self;
}

- (void *)formatContextHandle {
	return _formatContext;
}

- (const void *)videoCodecHandle {
	return _videoCodec;
}

- (const void *)videoStreamHandle {
	return _videoStream;
}

- (void)terminate {
	if (self.renderer) {
		[self.renderer terminate];
	}
	if (_formatContext) {
		avformat_close_input(&_formatContext);
	}
}

- (NSObject<ZENFrameRenderController> *)frameRenderController {
	if (!self.renderer) {
		self.renderer = [[ZENLibAVRenderController alloc] initWithInfoController:self];
	}
	return self.renderer;
}

- (NSUInteger)durationMicroseconds {
	NSAssert(AV_TIME_BASE == 1000000, @"Expected libav AV_TIME_BASE 1000000 for microseconds, instead = %d", AV_TIME_BASE);
	return _formatContext->duration;
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

- (NSString *)videoCodecName {
	NSString *codec = @"Unknown";
	if (_videoCodec) {
		codec = [NSString stringWithCString:_videoCodec->name encoding:NSASCIIStringEncoding];
	}
	return codec;
}

- (NSString *)audioCodecName {
	NSString *codec = @"Unknown";
	if (_audioCodec) {
		codec = [NSString stringWithCString:_audioCodec->name encoding:NSASCIIStringEncoding];
	}
	return codec;
}

- (NSString *)videoCodecLongName {
	NSString *codec = @"Unknown";
	if (_videoCodec) {
		codec = [NSString stringWithCString:_videoCodec->long_name encoding:NSASCIIStringEncoding];
	}
	return codec;
}

- (NSString *)audioCodecLongName {
	NSString *codec = @"Unknown";
	if (_audioCodec) {
		codec = [NSString stringWithCString:_audioCodec->long_name encoding:NSASCIIStringEncoding];
	}
	return codec;
}

@end
