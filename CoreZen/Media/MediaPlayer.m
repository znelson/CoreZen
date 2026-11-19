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

ZENObjectCache *ZENGetWeakMediaPlayerCache(void) {
	static ZENObjectCache *cache = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		cache = [ZENObjectCache weakObjectCache];
	});
	return cache;
}

typedef NS_ENUM(NSInteger, ZENSeekKind) {
	ZENSeekKindRelativeSeconds,
	ZENSeekKindAbsoluteSeconds,
	ZENSeekKindAbsolutePercentage,
};

@interface ZENMediaPlayer ()

@property (nonatomic) BOOL terminated;

// The latest seek that hasn't reached mpv yet, because the file hadn't loaded
// or another seek was running. Main thread only.
@property (nonatomic) BOOL hasPendingSeek;
@property (nonatomic) ZENSeekKind pendingSeekKind;
@property (nonatomic) double pendingSeekTarget;

// The file loadFileURL: asked for last, and the ID mpv gave it. mpv reports the
// files it replaces after it starts on the next one, so status only follows
// events about this one. Main thread only.
@property (nonatomic, strong) NSURL *loadingURL;
@property (nonatomic) int64_t loadingEntryID;
// The file mpv started on last, which FILE_LOADED is about
@property (nonatomic) int64_t startedEntryID;

- (void)failWithReason:(NSString *)reason;
- (void)requestSeek:(ZENSeekKind)kind target:(double)target;
- (void)startPendingSeek;

@end

NSErrorDomain const ZENMediaPlayerErrorDomain = @"ZENMediaPlayerErrorDomain";

@implementation ZENMediaPlayer

@synthesize identifier = _identifier;

- (instancetype)init {
	self = [super init];
	if (self) {
		_terminated = NO;
		_status = ZENMediaPlayerStatusIdle;
		_loadingEntryID = -1;
		_startedEntryID = -1;
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
	// A seek still waiting from the previous file doesn't apply to this one
	self.hasPendingSeek = NO;
	self.loadingURL = url;
	self.error = nil;
	self.status = ZENMediaPlayerStatusLoading;

	NSString *failure = nil;
	self.loadingEntryID = [self.playerController openFileURL:url failure:&failure];
	if (self.loadingEntryID < 0) {
		[self failWithReason:failure];
	}
}

- (void)failWithReason:(NSString *)reason {
	NSString *description = [NSString stringWithFormat:@"Couldn't play %@: %@", self.loadingURL.lastPathComponent, reason];
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:description forKey:NSLocalizedDescriptionKey];
	if (self.loadingURL) {
		userInfo[NSURLErrorKey] = self.loadingURL;
	}
	self.error = [NSError errorWithDomain:ZENMediaPlayerErrorDomain code:ZENMediaPlayerErrorPlaybackFailed userInfo:userInfo];
	self.status = ZENMediaPlayerStatusFailed;
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
	[self requestSeek:ZENSeekKindRelativeSeconds target:seconds];
}

- (void)seekAbsoluteSeconds:(double)seconds {
	[self requestSeek:ZENSeekKindAbsoluteSeconds target:seconds];
}

- (void)seekAbsolutePercentage:(double)percentage {
	[self requestSeek:ZENSeekKindAbsolutePercentage target:percentage];
}

#pragma mark - [private] Seeking

- (void)requestSeek:(ZENSeekKind)kind target:(double)target {
	// Only the latest seek is kept, except that relative seeks add up
	if (self.hasPendingSeek && kind == ZENSeekKindRelativeSeconds && self.pendingSeekKind == ZENSeekKindRelativeSeconds) {
		target += self.pendingSeekTarget;
	}
	self.pendingSeekKind = kind;
	self.pendingSeekTarget = target;
	self.hasPendingSeek = YES;

	[self startPendingSeek];
}

- (void)startPendingSeek {
	// One seek runs at a time. The pending seek starts when mpv reports that the
	// running one has finished, or that the file has loaded.
	if (!self.hasPendingSeek || self.seeking) {
		return;
	}

	ZENMPVCommandResult result = ZENMPVCommandResultRejected;
	switch (self.pendingSeekKind) {
		case ZENSeekKindRelativeSeconds:
			result = [self.playerController seekBySeconds:self.pendingSeekTarget];
			break;
		case ZENSeekKindAbsoluteSeconds:
			result = [self.playerController seekToSeconds:self.pendingSeekTarget];
			break;
		case ZENSeekKindAbsolutePercentage:
			result = [self.playerController seekToPercentage:self.pendingSeekTarget];
			break;
	}

	switch (result) {
		case ZENMPVCommandResultAccepted:
			self.hasPendingSeek = NO;
			self.seeking = YES;
			break;
		case ZENMPVCommandResultNotReady:
			// Usually the file hasn't loaded yet; try again when it has
			break;
		case ZENMPVCommandResultRejected:
			self.hasPendingSeek = NO;
			break;
	}
}

- (void)playerControllerDidStartFile:(int64_t)entryID {
	self.startedEntryID = entryID;
}

- (void)playerControllerDidLoadFile {
	if (self.startedEntryID == self.loadingEntryID) {
		self.status = ZENMediaPlayerStatusReady;
	}
	[self startPendingSeek];
}

- (void)playerControllerDidRestartPlayback {
	// A seek finished, or playback started after loading
	self.seeking = NO;
	[self startPendingSeek];
}

- (void)playerControllerDidEndFile:(int64_t)entryID reason:(ZENMPVEndReason)reason failure:(NSString *)failure {
	// A seek running when the file ended won't report finishing
	self.seeking = NO;

	// The end of a file that a newer load replaced says nothing about that load
	if (entryID != self.loadingEntryID) {
		return;
	}
	switch (reason) {
		case ZENMPVEndReasonFinished:
			self.status = ZENMediaPlayerStatusEnded;
			break;
		case ZENMPVEndReasonFailed:
			[self failWithReason:failure];
			break;
		case ZENMPVEndReasonStopped:
			self.status = ZENMediaPlayerStatusIdle;
			break;
	}
}

@end
