//
//  MediaFile.m
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import "MediaFile+Private.h"
#import "LibAVInfoController.h"

@interface ZENMediaFile ()

@property (nonatomic, strong) NSURL *fileURL;

- (instancetype)initWithURL:(NSURL *)url;

@end

@implementation ZENMediaFile

- (instancetype)initWithURL:(NSURL *)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_mediaInfoController = [[ZENLibAVInfoController alloc] initWithMediaFile:self];
	}
	return self;
}

+ (instancetype)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *mf = [[ZENMediaFile alloc] initWithURL:url];
	return mf;
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
