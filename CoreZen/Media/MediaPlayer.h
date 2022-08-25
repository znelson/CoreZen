//
//  MediaPlayer.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>

@class ZENMediaPlayerView;
@protocol ZENMediaPlayerController;

@interface ZENMediaPlayer : NSObject

- (instancetype)initWithFileURL:(NSURL*)url;

@property (nonatomic, strong, readonly) NSURL *fileURL;
@property (nonatomic, strong, readonly) NSObject<ZENMediaPlayerController> *playerController;
@property (nonatomic, strong, readonly) ZENMediaPlayerView *playerView;

// Observe these properties for updates to the UI. They will only change on the main thread.
@property (nonatomic, readonly) BOOL paused;

- (void)startPlayback;
- (void)pausePlayback;

@end
