//
//  MediaPlayerView.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;
@protocol ZENMediaPlayerRenderController;

@interface ZENMediaPlayerView : NSOpenGLView

@property (nonatomic, strong, readonly) NSObject<ZENMediaPlayerRenderController> *renderController;
@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

- (void)attachPlayer:(ZENMediaPlayer *)player;

- (void)lockViewContext;
- (void)unlockViewContext;

@end
