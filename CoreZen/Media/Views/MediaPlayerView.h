//
//  MediaPlayerView.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

// NSOpenGLView is deprecated, but libmpv's render API only offers OpenGL (plus a
// CPU-only renderer) until mpv ships a Vulkan render API (mpv issue #18343).
// CoreZen builds with GL_SILENCE_DEPRECATION; this keeps the warning out of apps
// that import this header without it.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@interface ZENMediaPlayerView : NSOpenGLView
#pragma clang diagnostic pop

@property (nonatomic, weak, readonly, nullable) ZENMediaPlayer *player;

// Attach a player to this player view, create view render context. A view shows
// one player and a player renders into one view, so this first detaches the
// view's current player, and detaches the new player from any other view (both
// are left paused).
- (void)attachPlayer:(ZENMediaPlayer *)player;

// Detach the player from this player view, destroy view render context, but leave player paused
- (void)detachPlayer;

@end

NS_ASSUME_NONNULL_END
