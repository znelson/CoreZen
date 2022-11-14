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

@interface ZENMediaPlayer ()

@property (nonatomic) BOOL terminated;
@property (nonatomic, strong) NSURL *fileURL;

@end

@implementation ZENMediaPlayer

@synthesize identifier=_identifier;

- (instancetype)init {
	self = [super init];
	if (self) {
		_terminated = NO;
		_playerController = [[ZENMPVPlayerController alloc] initWithPlayer:self];
		_identifier = _playerController.identifier;
		
		ZENObjectCache *cache = ZENGetWeakMediaPlayerCache();
		[cache cacheObject:self];
	}
	return self;
}

- (void)dealloc {
	if (!self.terminated) {
		NSLog(@"WARNING: ZENMediaPlayer -terminatePlayer was not called before -dealloc (%@)", self.fileURL);
		[self terminatePlayer];
	}
}

- (void)terminatePlayer {
	if (self.terminated) {
		NSLog(@"WARNING: ZENMediaPlayer -terminatePlayer called more than once (%@)", self.fileURL);
	} else {
		if (self.playerView) {
			[self.playerView terminatePlayerView];
		}
		[self detachPlayerView];
		[self.playerController terminate];
		
		ZENObjectCache *cache = ZENGetWeakMediaPlayerCache();
		[cache removeObject:self.identifier];
		
		self.terminated = YES;
	}
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

- (void)loadFileURL:(NSURL *)url {
	[self.playerController openFileURL:url];
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
	if (!self.seeking) {
		self.seeking = YES;
		[self.playerController seekBySeconds:seconds];
	}
}

- (void)seekAbsoluteSeconds:(double)seconds {
	if (!self.seeking) {
		self.seeking = YES;
		[self.playerController seekToSeconds:seconds];
	}
}

- (void)seekAbsolutePercentage:(double)percentage {
	if (!self.seeking) {
		self.seeking = YES;
		[self.playerController seekToPercentage:percentage];
	}
}

@end
