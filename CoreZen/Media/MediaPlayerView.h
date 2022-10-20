//
//  MediaPlayerView.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;

@interface ZENMediaPlayerView : NSOpenGLView

@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

// Attach a player to this player view, create view render context
- (void)attachPlayer:(ZENMediaPlayer *)player;

// Detach the player from this player view, destroy view render context, but leave player paused
- (void)detachPlayer;

@end
