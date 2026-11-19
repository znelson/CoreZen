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

/// What a media player is doing with the file it was last asked to load.
typedef NS_ENUM(NSInteger, ZENMediaPlayerStatus) {
	/// No file: none has been loaded yet, or playback was stopped.
	ZENMediaPlayerStatusIdle,
	/// The player was asked to load a file, which hasn't loaded yet.
	ZENMediaPlayerStatusLoading,
	/// The file has loaded, and can play and seek.
	ZENMediaPlayerStatusReady,
	/// Playback reached the end of the file, which mpv then closes.
	ZENMediaPlayerStatusEnded,
	/// The file couldn't be loaded or played. The player's error says why.
	ZENMediaPlayerStatusFailed,
};

/// The domain of the errors that say why a media player couldn't play a file.
extern NSErrorDomain const ZENMediaPlayerErrorDomain;

/// Why a media player couldn't play a file.
typedef NS_ERROR_ENUM(ZENMediaPlayerErrorDomain, ZENMediaPlayerErrorCode){
	/// mpv couldn't load or play the file.
	///
	/// The description gives mpv's reason, like "loading failed" for a missing
	/// file, and `NSURLErrorKey` gives the file's URL.
	ZENMediaPlayerErrorPlaybackFailed = 1,
};

/// Plays a media file with mpv.
///
/// A player shows its video in the ``ZENMediaPlayerView`` attached to it. Use a
/// player on the main thread: its properties change only there, so a UI can
/// observe them with key-value observing. Call ``terminatePlayer`` once you're
/// done with a player, or ``terminateAllPlayers`` before the app quits.
///
/// ### Seeking
///
/// Seeks run one at a time. A seek asked for before the loaded file is ready, or
/// while another seek is running, waits and then runs. Only the latest waiting
/// seek is kept, except that relative seeks add up. Loading a new file drops a
/// waiting seek.
@interface ZENMediaPlayer : NSObject <ZENIdentifiable>

/// The view showing the player's video, or nil while none is attached.
@property (nonatomic, strong, readonly, nullable) ZENMediaPlayerView *playerView;

/// The file mpv has open, or nil while there's none.
@property (nonatomic, strong, readonly, nullable) NSURL *fileURL;

/// Whether playback is paused.
@property (nonatomic, readonly) BOOL paused;

/// The position in the file, from 0 to 100.
@property (nonatomic, readonly) double positionPercent;

/// Whether a seek is running.
@property (nonatomic, readonly) BOOL seeking;

/// What the player is doing with the file it was last asked to load.
@property (nonatomic, readonly) ZENMediaPlayerStatus status;

/// Why the last file failed, while the status is
/// ``ZENMediaPlayerStatus/ZENMediaPlayerStatusFailed``.
@property (nonatomic, strong, readonly, nullable) NSError *error;

/// The position in the file in seconds, or 0 until mpv knows it.
@property (nonatomic, readonly) double positionSeconds;

/// The length of the file in seconds, or 0 until mpv knows it.
@property (nonatomic, readonly) double durationSeconds;

/// Detaches the player's view, and shuts its mpv instance down.
///
/// A player released without this terminates itself, and logs that it wasn't
/// terminated first.
- (void)terminatePlayer;

/// Terminates every player that hasn't been terminated.
///
/// Call it before the app quits.
+ (void)terminateAllPlayers;

/// Starts loading a file in place of the current one, paused.
///
/// The status becomes ``ZENMediaPlayerStatus/ZENMediaPlayerStatusLoading``,
/// then ``ZENMediaPlayerStatus/ZENMediaPlayerStatusReady`` or
/// ``ZENMediaPlayerStatus/ZENMediaPlayerStatusFailed``.
- (void)loadFileURL:(NSURL *)url;

/// Starts or resumes playback.
- (void)startPlayback;

/// Pauses playback.
- (void)pausePlayback;

/// Pauses, then shows the next frame, or the previous one if `forward` is NO.
- (void)stepOneFrame:(BOOL)forward;

/// Seeks forward by a number of seconds, or back if it's negative.
///
/// Call it on the main thread. The class overview says how seeks wait for each other.
- (void)seekRelativeSeconds:(double)seconds;

/// Seeks to a time in seconds from the start of the file.
///
/// Call it on the main thread. The class overview says how seeks wait for each other.
- (void)seekAbsoluteSeconds:(double)seconds;

/// Seeks to a position in the file, from 0 to 100.
///
/// Call it on the main thread. The class overview says how seeks wait for each other.
- (void)seekAbsolutePercentage:(double)percentage;

@end

NS_ASSUME_NONNULL_END
