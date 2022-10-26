//
//  MediaPlayer.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MediaPlayer+Private.h"
#import "MediaPlayerView+Private.h"
#import "MPVPlayerController.h"
#import "ObjectCache.h"
#import <stdatomic.h>

ZENObjectCache* ZENGetWeakMediaPlayerCache(void) {
	static ZENObjectCache *cache = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		cache = [ZENObjectCache weakObjectCache];
	});
	return cache;
}

ZENIdentifier ZENGetNextMediaPlayerIdentifier(void) {
	static atomic_int_fast64_t nextIdentifier = 1;
	return atomic_fetch_add(&nextIdentifier, 1);
}

@implementation ZENMediaPlayer

- (instancetype)initWithFileURL:(NSURL*)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_playerController = [[ZENMPVPlayerController alloc] initWithPlayer:self];
		_identifier = ZENGetNextMediaPlayerIdentifier();
		
		ZENObjectCache *cache = ZENGetWeakMediaPlayerCache();
		[cache cacheObject:self];
	}
	return self;
}

- (void)terminatePlayer {
	if (self.playerView) {
		[self.playerView terminatePlayerView];
	}
	[self detachPlayerView];
	[self.playerController terminate];
	
	ZENObjectCache *cache = ZENGetWeakMediaPlayerCache();
	[cache removeObject:self.identifier];
}

+ (void)terminateAllPlayers {
	ZENObjectCache *cache = ZENGetWeakMediaPlayerCache();
	NSArray<id<ZENIdentifiable>> *objs = cache.allCachedObjects;
	for (ZENMediaPlayer *player in objs) {
		[player terminatePlayer];
	}
	[cache removeAllObjects];
}

- (void)attachPlayerView:(ZENMediaPlayerView *)view {
	self.playerView = view;
}

- (void)detachPlayerView {
	if (self.playerView) {
		[self pausePlayback];
		self.playerView = nil;
	}
}

- (void)startPlayback {
	[self.playerController startPlayback];
}

- (void)pausePlayback {
	[self.playerController pausePlayback];
}

- (void)frameStepBack {
	[self.playerController frameStepBack];
}

- (void)frameStepForward {
	[self.playerController frameStepForward];
}

@end
