//
//  MediaFile.m
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import "MediaFile.h"

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

@interface ZENMediaFile ()
{
	AVFormatContext *_formatContext;
	
	// Video
	AVCodec *_videoCodec;
	AVCodecParameters *_videoCodecParameters;
	AVCodecContext *_videoCodecContext;
	
	// Audio
	AVCodec *_audioCodec;
	AVCodecParameters *_audioCodecParameters;
	AVCodecContext *_audioCodecContext;
}

@property (nonatomic, strong) NSURL *fileURL;

- (instancetype)initWithURL:(NSURL *)url;
- (void)avInit:(NSString *)filePath;

@end

@implementation ZENMediaFile

- (void)dealloc {
	if (_formatContext) {
		avformat_close_input(&_formatContext);
	}
	if (_videoCodecContext) {
		avcodec_free_context(&_videoCodecContext);
	}
	if (_audioCodecContext) {
		avcodec_free_context(&_audioCodecContext);
	}
}

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
			const AVCodec *constVideoCodec = _videoCodec;
			const int videoStreamIndex = av_find_best_stream(_formatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &constVideoCodec, 0);
			if (videoStreamIndex > -1) {
				// av_find_best_stream() documentation:
				// If av_find_best_stream returns successfully and decoder_ret (&_videoCodec) is not NULL,
				// then *decoder_ret (_videoCodec) is guaranteed to be set to a valid AVCodec.
				
				_videoCodecParameters = _formatContext->streams[videoStreamIndex]->codecpar;

#if 0
				// This part only needs to happen if we're going to fetch video frames
				_videoCodecContext = avcodec_alloc_context3(_videoCodec);
				result = avcodec_parameters_to_context(_videoCodecContext, _videoCodecParameters);
				result = avcodec_open2(_videoCodecContext, _videoCodec, NULL);
#endif
			} else {
				ZENLogAVFindBestStreamError(filePath, videoStreamIndex, AVMEDIA_TYPE_VIDEO);
			}
			
			const AVCodec *constAudioCodec = _audioCodec;
			const int audioStreamIndex = av_find_best_stream(_formatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &constAudioCodec, 0);
			if (audioStreamIndex > -1) {
				_audioCodecParameters = _formatContext->streams[audioStreamIndex]->codecpar;
				
#if 0
				// This part only needs to happen if we're going to fetch audio frames
				_audioCodecContext = avcodec_alloc_context3(_audioCodec);
				result = avcodec_parameters_to_context(_audioCodecContext, _audioCodecParameters);
				result = avcodec_open2(_audioCodecContext, _audioCodec, NULL);
#endif
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

- (instancetype)initWithURL:(NSURL *)url {
	self = [super init];
	if (self) {
		_formatContext = NULL;
		
		_videoCodec = NULL;
		_videoCodecParameters = NULL;
		_videoCodecContext = NULL;
		
		_audioCodec = NULL;
		_audioCodecParameters = NULL;
		_audioCodecContext = NULL;
		
		_fileURL = url;
		
		[self avInit:self.fileURL.path];
	}
	return self;
}

+ (instancetype)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *wrapper = [[ZENMediaFile alloc] initWithURL:url];
	return wrapper;
}

- (NSUInteger)durationMicroseconds {
	NSAssert(AV_TIME_BASE == 1000000, @"Expected libav AV_TIME_BASE 1000000 for microseconds, instead = %d", AV_TIME_BASE);
	return _formatContext->duration;
}

- (NSUInteger)frameWidth {
	NSUInteger width = 0;
	if (_videoCodecParameters) {
		width = ((NSUInteger)_videoCodecParameters->width);
	}
	return width;
}

- (NSUInteger)frameHeight {
	NSUInteger height = 0;
	if (_videoCodecParameters) {
		height = ((NSUInteger)_videoCodecParameters->height);
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
