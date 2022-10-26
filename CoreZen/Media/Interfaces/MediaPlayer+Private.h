//
//  MediaPlayer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayer.h>

@protocol ZENMediaPlayerController;

@interface ZENMediaPlayer ()

@property (nonatomic) ZENIdentifier identifier;

@property (nonatomic, strong) ZENMediaPlayerView *playerView;
@property (nonatomic, strong, readonly) NSObject<ZENMediaPlayerController> *playerController;

@property (nonatomic) BOOL paused;
@property (nonatomic) double positionPercent;

// Reciprocal of ZENMediaPlayerView attachPlayer:
- (void)attachPlayerView:(ZENMediaPlayerView *)view;

// Reciprocal of ZENMediaPlayerView detachPlayer, leaves player paused
- (void)detachPlayerView;

@end
