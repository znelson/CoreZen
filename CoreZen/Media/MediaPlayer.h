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

- (void)startPlayback;
- (void)pausePlayback;

@end
