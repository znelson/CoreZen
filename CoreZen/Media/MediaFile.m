//
//  MediaFile.m
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import "MediaFile+Private.h"
#import "LibAVInfoController.h"
#import "FrameRenderer.h"

@interface ZENMediaFile ()

@property (nonatomic, strong) NSURL *fileURL;

- (instancetype)initWithURL:(NSURL *)url;

@end

@implementation ZENMediaFile

@synthesize identifier=_identifier;

- (instancetype)initWithURL:(NSURL *)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_mediaInfoController = [[ZENLibAVInfoController alloc] initWithMediaFile:self];
		_identifier = _mediaInfoController.identifier;
	}
	return self;
}

+ (instancetype)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *mediaFile = [[ZENMediaFile alloc] initWithURL:url];
	return mediaFile;
}

- (ZENFrameRenderer *)frameRenderer {
	NSObject<ZENFrameRenderController> *controller = self.mediaInfoController.frameRenderController;
	ZENFrameRenderer *frameRenderer = [[ZENFrameRenderer alloc] initWithController:controller];
	return frameRenderer;
}

- (NSUInteger)durationMicroseconds {
	return self.mediaInfoController.durationMicroseconds;
}

- (NSUInteger)frameWidth {
	return self.mediaInfoController.frameWidth;
}

- (NSUInteger)frameHeight {
	return self.mediaInfoController.frameHeight;
}

- (NSString *)videoCodecName {
	return self.mediaInfoController.videoCodecName;
}

- (NSString *)audioCodecName {
	return self.mediaInfoController.audioCodecName;
}

- (NSString *)videoCodecLongName {
	return self.mediaInfoController.videoCodecLongName;
}

- (NSString *)audioCodecLongName {
	return self.mediaInfoController.audioCodecLongName;
}

@end
