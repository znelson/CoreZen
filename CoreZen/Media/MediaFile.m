//
//  MediaFile.m
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import "MediaFile+Private.h"
#import "LibAVInfoController.h"
#import "LibAVRenderController.h"
#import "ObjectCache.h"
#import "Log.h"

ZENObjectCache *ZENGetWeakMediaFileCache(void) {
	static ZENObjectCache *cache = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		cache = [ZENObjectCache weakObjectCache];
	});
	return cache;
}

@interface ZENMediaFile ()

@property (nonatomic) BOOL terminated;

- (instancetype)initWithURL:(NSURL *)url;
- (BOOL)turnedOnItsSide;
- (NSUInteger)stretchedFrameWidth;

@end

@implementation ZENMediaFile

@synthesize identifier = _identifier;

- (instancetype)initWithURL:(NSURL *)url {
	self = [super init];
	if (self) {
		_terminated = NO;
		_fileURL = url;
		_mediaInfoController = [[ZENLibAVInfoController alloc] initWithMediaPath:url.path];
		_identifier = _mediaInfoController.identifier;

		ZENObjectCache *cache = ZENGetWeakMediaFileCache();
		[cache cacheObject:self];
	}
	return self;
}

- (void)dealloc {
	if (!self.terminated) {
		os_log(ZENLogMedia(), "terminateMediaFile wasn't called before the media file for %@ was released", self.fileURL.path);
		[self terminateMediaFile];
	}
}

+ (instancetype)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *mediaFile = [[ZENMediaFile alloc] initWithURL:url];
	return mediaFile;
}

- (void)terminateMediaFile {
	if (self.terminated) {
		os_log(ZENLogMedia(), "terminateMediaFile was called more than once for %@", self.fileURL.path);
	} else {
		// mediaInfoController owns the lazily created frameRenderController
		// and will terminate it here if it was ever created
		[self.mediaInfoController terminate];

		ZENObjectCache *cache = ZENGetWeakMediaFileCache();
		[cache removeObject:self.identifier];

		self.terminated = YES;
	}
}

+ (void)terminateAllMediaFiles {
	ZENObjectCache *cache = ZENGetWeakMediaFileCache();
	NSArray<id<ZENIdentifiable>> *objs = cache.allCachedObjects;
	for (ZENMediaFile *mediaFile in objs) {
		[mediaFile terminateMediaFile];
	}
	[cache removeAllObjects];
}

- (NSUInteger)durationMicroseconds {
	return self.mediaInfoController.durationMicroseconds;
}

// A quarter turn swaps the stored frame's width and height
- (BOOL)turnedOnItsSide {
	NSUInteger rotation = self.rotationDegrees;
	return rotation == 90 || rotation == 270;
}

// The stored frame's width as shown: its pixels stretched to their aspect ratio.
// The height stays as stored, as video players show it.
- (NSUInteger)stretchedFrameWidth {
	return (NSUInteger)lround(self.mediaInfoController.frameWidth * self.pixelAspectRatio);
}

- (NSUInteger)frameWidth {
	return self.turnedOnItsSide ? self.mediaInfoController.frameHeight : self.stretchedFrameWidth;
}

- (NSUInteger)frameHeight {
	return self.turnedOnItsSide ? self.stretchedFrameWidth : self.mediaInfoController.frameHeight;
}

- (double)pixelAspectRatio {
	return self.mediaInfoController.pixelAspectRatio;
}

- (NSUInteger)rotationDegrees {
	return self.mediaInfoController.rotationDegrees;
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
