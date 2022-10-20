//
//  MediaPlayerView+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <CoreZen/MediaPlayerView.h>

@protocol ZENMediaPlayerRenderController;

@interface ZENMediaPlayerView ()

@property (nonatomic, weak) ZENMediaPlayer *player;
@property (nonatomic, strong, readonly) NSObject<ZENMediaPlayerRenderController> *renderController;

// Destroy view render context and clear player
// Does not call [ZENMediaPlayer detachPlayer], so this can be called from -detachPlayer
- (void)terminatePlayerView;

- (void)lockViewContext;
- (void)unlockViewContext;

@end
