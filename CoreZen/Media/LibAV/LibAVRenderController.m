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
	AVCodecContext *_videoCodecContext;
	AVCodecContext *_audioCodecContext;
}

@property (nonatomic, weak) ZENMediaFile *mediaFile;

- (void)avInit:(ZENLibAVInfoController *)infoController;

@end

@implementation ZENLibAVRenderController

- (void)avInit:(ZENLibAVInfoController *)infoController {
	const AVCodec *videoCodec = infoController.videoCodecHandle;
	const AVCodecParameters *videoCodecParams = infoController.videoCodecParamsHandle;
	
	const AVCodec *audioCodec = infoController.audioCodecHandle;
	const AVCodecParameters *audioCodecParams = infoController.audioCodecParamsHandle;
	
	_videoCodecContext = avcodec_alloc_context3(videoCodec);
	int result = avcodec_parameters_to_context(_videoCodecContext, videoCodecParams);
	result = avcodec_open2(_videoCodecContext, videoCodec, NULL);
	
	_audioCodecContext = avcodec_alloc_context3(audioCodec);
	result = avcodec_parameters_to_context(_audioCodecContext, audioCodecParams);
	result = avcodec_open2(_audioCodecContext, audioCodec, NULL);
}

- (instancetype)initWithInfoController:(ZENLibAVInfoController *)infoController {
	self = [super init];
	if (self) {
		_mediaFile = infoController.mediaFile;
		
		[self avInit:infoController];
	}
	return self;
}

- (void)terminate {
	
}

@end
