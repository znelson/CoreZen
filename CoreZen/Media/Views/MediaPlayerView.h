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

// Attach a player to this player view, create view render context. A view shows
// one player and a player renders into one view, so this first detaches the
// view's current player, and detaches the new player from any other view (both
// are left paused).
- (void)attachPlayer:(ZENMediaPlayer *)player;

// Detach the player from this player view, destroy view render context, but leave player paused
- (void)detachPlayer;

@end
