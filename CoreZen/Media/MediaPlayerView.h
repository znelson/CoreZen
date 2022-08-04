//
//  MediaPlayerView.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;
@protocol ZENMediaPlayerViewController;

@interface ZENMediaPlayerView : NSOpenGLView

@property (nonatomic, strong, readonly) NSObject<ZENMediaPlayerViewController> *playerViewController;
@property (nonatomic, weak) ZENMediaPlayer *player;

- (void)attachPlayer:(ZENMediaPlayer *)player;

- (void)lockViewContext;
- (void)unlockViewContext;

@end
