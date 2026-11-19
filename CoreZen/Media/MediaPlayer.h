//
//  MediaPlayer.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENMediaPlayerView;

NS_ASSUME_NONNULL_BEGIN

// What the player is doing with the file it was last asked to load
typedef NS_ENUM(NSInteger, ZENMediaPlayerStatus) {
	// No file: none has been loaded yet, or playback was stopped
	ZENMediaPlayerStatusIdle,
	// loadFileURL: was called, and the file hasn't loaded yet
	ZENMediaPlayerStatusLoading,
	// The file has loaded, and can play and seek
	ZENMediaPlayerStatusReady,
	// Playback reached the end of the file, which mpv then closes
	ZENMediaPlayerStatusEnded,
	// The file couldn't be loaded or played. error says why.
	ZENMediaPlayerStatusFailed,
};

extern NSErrorDomain const ZENMediaPlayerErrorDomain;

typedef NS_ERROR_ENUM(ZENMediaPlayerErrorDomain, ZENMediaPlayerErrorCode){
	// mpv couldn't load or play the file. The description gives its reason, like
	// "loading failed" for a missing file, and NSURLErrorKey the file's URL.
	ZENMediaPlayerErrorPlaybackFailed = 1,
};

@interface ZENMediaPlayer : NSObject <ZENIdentifiable>

// nil while no view is attached
@property (nonatomic, strong, readonly, nullable) ZENMediaPlayerView *playerView;

// Observe these properties for updates to the UI. They will only change on the main thread.
@property (nonatomic, strong, readonly, nullable) NSURL *fileURL;
@property (nonatomic, readonly) BOOL paused;
@property (nonatomic, readonly) double positionPercent;
@property (nonatomic, readonly) BOOL seeking;
@property (nonatomic, readonly) ZENMediaPlayerStatus status;
// Why the last file failed, while status is ZENMediaPlayerStatusFailed
@property (nonatomic, strong, readonly, nullable) NSError *error;
// The position and length of the file in seconds, or 0 until mpv knows them
@property (nonatomic, readonly) double positionSeconds;
@property (nonatomic, readonly) double durationSeconds;

// Terminate and detach the player view, terminate player controller
- (void)terminatePlayer;

// Call before application terminates to terminate all ZENMediaPlayer instances
+ (void)terminateAllPlayers;

// Starts loading url in place of the current file, paused. status becomes
// ZENMediaPlayerStatusLoading, then Ready or Failed.
- (void)loadFileURL:(NSURL *)url;

- (void)startPlayback;
- (void)pausePlayback;

- (void)stepOneFrame:(BOOL)forward;

// Seeks run one at a time. A seek requested before the loaded file is ready, or
// while another seek is running, waits and then runs. Only the latest waiting
// seek is kept, except that relative seeks add up. Loading a new file drops a
// waiting seek. Call these on the main thread.
- (void)seekRelativeSeconds:(double)seconds;

- (void)seekAbsoluteSeconds:(double)seconds;
- (void)seekAbsolutePercentage:(double)percentage;

@end

NS_ASSUME_NONNULL_END
