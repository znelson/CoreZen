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

@property (nonatomic, strong, readonly) ZENMediaPlayerView *playerView;

// Observe these properties for updates to the UI. They will only change on the main thread.
@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) double positionPercent;
@property (nonatomic, readonly) BOOL seeking;

// Terminate and detach the player view, terminate player controller
- (void)terminatePlayer;

// Call before application terminates to terminate all ZENMediaPlayer instances
+ (void)terminateAllPlayers;

- (void)loadFileURL:(NSURL *)url;

- (void)startPlayback;
- (void)pausePlayback;

- (void)stepOneFrame:(BOOL)forward;

- (void)seekRelativeSeconds:(double)seconds;

- (void)seekAbsoluteSeconds:(double)seconds;
- (void)seekAbsolutePercentage:(double)percentage;

@end
