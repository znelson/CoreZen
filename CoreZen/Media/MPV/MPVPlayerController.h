//
//  MPVPlayerController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENMediaPlayer;
struct mpv_handle;

// How mpv responded to a command
typedef NS_ENUM(NSInteger, ZENMPVCommandResult) {
	ZENMPVCommandResultAccepted,
	// The command couldn't run in mpv's current state, e.g. a seek before the
	// file has loaded. It may succeed later.
	ZENMPVCommandResultNotReady,
	// mpv rejected the command or its arguments, e.g. a seek to NaN
	ZENMPVCommandResultRejected,
};

@interface ZENMPVPlayerController : NSObject <ZENIdentifiable>

- (instancetype)initWithPlayer:(ZENMediaPlayer *)player;

- (void)terminate;

@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

@property (nonatomic, strong, readonly) NSString *clientName;
@property (nonatomic, strong, readonly) NSString *version;

- (struct mpv_handle *)playerHandle;

- (void)openFileURL:(NSURL *)url;

- (void)startPlayback;
- (void)pausePlayback;

- (void)frameStepBack;
- (void)frameStepForward;

- (ZENMPVCommandResult)seekBySeconds:(double)seconds;
- (ZENMPVCommandResult)seekToSeconds:(double)seconds;
- (ZENMPVCommandResult)seekToPercentage:(double)percentage;

@end
