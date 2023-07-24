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

- (void)seekBySeconds:(double)seconds;
- (void)seekToSeconds:(double)seconds;
- (void)seekToPercentage:(double)percentage;

@end
