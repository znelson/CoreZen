//
//  MediaPlayerControlsView.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreZen/ArchivedView.h>

@class ZENMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/// Buttons that control a media player.
///
/// They play and pause, step one frame back or forward, and skip back 3 or 10
/// seconds, or forward 6 or 15.
@interface ZENMediaPlayerControlsView : ZENArchivedView

/// The player the view works with, or nil while none is attached.
@property (nonatomic, weak, readonly, nullable) ZENMediaPlayer *player;

/// Makes the view work with a player, or with none if it's nil.
- (void)attachPlayer:(nullable ZENMediaPlayer *)player;

@end

NS_ASSUME_NONNULL_END
