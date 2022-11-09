//
//  LibAVRenderController.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "LibAVRenderController.h"
#import "LibAVInfoController.h"
#import "MediaFile.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <libavcodec/avcodec.h>
#import <libavformat/avformat.h>

#pragma clang diagnostic pop

@interface ZENLibAVRenderController ()
{
	AVCodecContext *_codecContext;
}

@property (nonatomic, weak) ZENMediaFile *mediaFile;

- (void)avInitWithCodec:(const AVCodec *)codec stream:(const AVStream *)stream;

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

@end
