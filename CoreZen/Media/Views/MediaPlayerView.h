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
/// Shows a media player's video.
///
/// It's an `NSOpenGLView`, because OpenGL is the only GPU rendering that mpv's
/// render API offers on macOS. A view shows one player, and a player renders
/// into one view.
@interface ZENMediaPlayerView : NSOpenGLView
#pragma clang diagnostic pop

/// The player whose video the view shows, or nil while none is attached.
@property (nonatomic, weak, readonly, nullable) ZENMediaPlayer *player;

/// Shows a player's video in this view.
///
/// It first detaches the view's current player, and detaches the new player
/// from any other view. Both are left paused.
- (void)attachPlayer:(ZENMediaPlayer *)player;

/// Stops showing the player's video, and leaves the player paused.
- (void)detachPlayer;

@end

NS_ASSUME_NONNULL_END
