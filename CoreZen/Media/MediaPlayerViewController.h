//
//  MediaPlayerViewController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;

@protocol ZENMediaPlayerViewController <NSObject>

- (void)createRenderContextForPlayer:(ZENMediaPlayer *)player;
- (void)destroyRenderContext;

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

@end
