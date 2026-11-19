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

@interface ZENMediaPlayerCTIView : ZENArchivedView

@property (nonatomic, weak, readonly, nullable) ZENMediaPlayer *player;

// nil detaches the current player
- (void)attachPlayer:(nullable ZENMediaPlayer *)player;

@end

NS_ASSUME_NONNULL_END
