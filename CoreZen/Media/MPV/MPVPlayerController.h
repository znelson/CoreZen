//
//  MPVPlayerController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/MediaPlayerController.h>

@class ZENMediaPlayer;

@interface ZENMPVPlayerController : NSObject <ZENMediaPlayerController>

- (instancetype)initWithPlayer:(ZENMediaPlayer *)player;

@property (nonatomic, weak, readonly) ZENMediaPlayer *player;

@property (nonatomic, strong, readonly) NSString *clientName;
@property (nonatomic, strong, readonly) NSString *version;

// ZENMediaPlayerController protocol
// (mpv_handle *)playerHandle;
- (void *)playerHandle;

- (void)startPlayback;

@end
