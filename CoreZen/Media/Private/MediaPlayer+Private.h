//
//  MediaPlayer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayer.h>
#import "MPVPlayerController.h"

@class ZENMPVPlayerController;

@interface ZENMediaPlayer ()

@property (nonatomic, strong) ZENMediaPlayerView *playerView;
@property (nonatomic, strong, readonly) ZENMPVPlayerController *playerController;

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) BOOL paused;
@property (nonatomic) double positionPercent;
@property (nonatomic) BOOL seeking;
@property (nonatomic) ZENMediaPlayerStatus status;
@property (nonatomic, strong) NSError *error;
@property (nonatomic) double positionSeconds;
@property (nonatomic) double durationSeconds;

// Reciprocal of ZENMediaPlayerView attachPlayer:
- (void)attachPlayerView:(ZENMediaPlayerView *)view;

// Reciprocal of ZENMediaPlayerView detachPlayer, leaves player paused
- (void)detachPlayerView;

// Called by ZENMPVPlayerController on the main thread as mpv reports events.
// entryID is the ID openFileURL: returned for the file the event is about.
- (void)playerControllerDidStartFile:(int64_t)entryID;
- (void)playerControllerDidLoadFile;
- (void)playerControllerDidRestartPlayback;
- (void)playerControllerDidEndFile:(int64_t)entryID reason:(ZENMPVEndReason)reason failure:(NSString *)failure;

@end
