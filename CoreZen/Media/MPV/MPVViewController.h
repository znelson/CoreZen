//
//  MPVViewController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/MediaPlayerViewController.h>

@class ZENMediaPlayerView;

@interface ZENMPVViewController : NSObject <ZENMediaPlayerViewController>

- (instancetype)initWithPlayerView:(ZENMediaPlayerView *)playerView;

@property (nonatomic, weak, readonly) ZENMediaPlayerView *playerView;

// ZENMediaPlayerViewController protocol
- (void)createRenderContextForPlayer:(ZENMediaPlayer *)player;
- (void)destroyRenderContext;

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

@end
