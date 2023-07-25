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

ZENObjectCache* ZENGetWeakMediaFileCache(void) {
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

@end

@implementation ZENMediaFile

@synthesize identifier=_identifier;

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
		NSLog(@"WARNING: ZENMediaFile -terminateMediaFile was not called before -dealloc (%@)", self.fileURL);
		[self terminateMediaFile];
	}
}

+ (instancetype)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *mediaFile = [[ZENMediaFile alloc] initWithURL:url];
	return mediaFile;
}

- (void)terminateMediaFile {
	if (self.terminated) {
		NSLog(@"WARNING: ZENMediaFile -terminateMediaFile called more than once (%@)", self.fileURL);
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
