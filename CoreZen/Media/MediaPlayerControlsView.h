//
//  MediaPlayerControlsView.h
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;

@interface ZENMediaPlayerControlsView : NSView

@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

- (void)attachPlayer:(ZENMediaPlayer *)player;

@end
