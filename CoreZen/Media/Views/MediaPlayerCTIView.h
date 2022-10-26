//
//  MediaPlayerCTIView.h
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import <Cocoa/Cocoa.h>
#import <CoreZen/ArchivedView.h>

@class ZENMediaPlayer;

@interface ZENMediaPlayerCTIView : ZENArchivedView

@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

- (void)attachPlayer:(ZENMediaPlayer *)player;

@end
