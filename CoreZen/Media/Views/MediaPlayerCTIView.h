//
//  MediaPlayerCTIView.h
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreZen/ArchivedView.h>

@class ZENMediaPlayer;

NS_ASSUME_NONNULL_BEGIN

/// A timeline for a media player, which shows and sets its position, and
/// previews the frame under the pointer.
///
/// Dragging along it seeks the player. While the pointer is over it, it shows a
/// frame from that point in the file, from frames it renders across each file
/// the player loads.
@interface ZENMediaPlayerCTIView : ZENArchivedView

/// The player the view works with, or nil while none is attached.
@property (nonatomic, weak, readonly, nullable) ZENMediaPlayer *player;

/// Makes the view work with a player, or with none if it's nil.
- (void)attachPlayer:(nullable ZENMediaPlayer *)player;

@end

NS_ASSUME_NONNULL_END
