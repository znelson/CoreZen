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

ZENObjectCache* ZENGetWeakMediaPlayerCache(void) {
	static ZENObjectCache *cache = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		cache = [ZENObjectCache weakObjectCache];
	});
	return cache;
}

@implementation ZENMediaPlayer

@synthesize identifier=_identifier;

- (instancetype)initWithFileURL:(NSURL*)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_playerController = [[ZENMPVPlayerController alloc] initWithPlayer:self];
		_identifier = _playerController.identifier;
		
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

- (void)stepOneFrame:(BOOL)forward {
	if (forward) {
		[self.playerController frameStepForward];
	} else {
		[self.playerController frameStepBack];
	}
}

- (void)seekRelativeSeconds:(double)seconds {
	[self.playerController seekBySeconds:seconds];
}

- (void)seekAbsoluteSeconds:(double)seconds {
	[self.playerController seekToSeconds:seconds];
}

- (void)seekAbsolutePercentage:(double)percentage {
	[self.playerController seekToPercentage:percentage];
}

@end
