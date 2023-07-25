//
//  MediaPlayer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayer.h>

@class ZENMPVPlayerController;

@interface ZENMediaPlayer ()

@property (nonatomic, strong) ZENMediaPlayerView *playerView;
@property (nonatomic, strong, readonly) ZENMPVPlayerController *playerController;

@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic) BOOL paused;
@property (nonatomic) double positionPercent;
@property (nonatomic) BOOL seeking;

// Reciprocal of ZENMediaPlayerView attachPlayer:
- (void)attachPlayerView:(ZENMediaPlayerView *)view;

// Reciprocal of ZENMediaPlayerView detachPlayer, leaves player paused
- (void)detachPlayerView;

@end
