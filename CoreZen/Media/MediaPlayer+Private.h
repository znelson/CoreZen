//
//  MediaPlayer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayer.h>

@interface ZENMediaPlayer ()

@property (nonatomic, strong) ZENMediaPlayerView *playerView;

- (void)attachPlayerView:(ZENMediaPlayerView *)view;

@end
