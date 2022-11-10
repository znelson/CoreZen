//
//  MediaPlayer.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENMediaPlayerView;

@interface ZENMediaPlayer : NSObject <ZENIdentifiable>

- (instancetype)initWithFileURL:(NSURL*)url;

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, strong, readonly) ZENMediaPlayerView *playerView;

// Observe these properties for updates to the UI. They will only change on the main thread.
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) double positionPercent;

// Terminate and detach the player view, terminate player controller
- (void)terminatePlayer;

// Call before application terminates to terminate all ZENMediaPlayer instances
+ (void)terminateAllPlayers;

- (void)startPlayback;
- (void)pausePlayback;

- (void)stepOneFrame:(BOOL)forward;
- (void)seekBySeconds:(double)seconds;
- (void)seekToSeconds:(double)seconds;
- (void)seekToPercentage:(double)percentage;

@end
