//
//  MediaPlayer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayer.h>

@interface ZENMediaPlayer ()

@property (nonatomic, strong) ZENMediaPlayerView *playerView;

@property (nonatomic) BOOL paused;

- (void)attachPlayerView:(ZENMediaPlayerView *)view;
- (void)detachPlayerView;

@end
