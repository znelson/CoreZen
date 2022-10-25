//
//  MediaPlayerController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>

@protocol ZENMediaPlayerController <NSObject>

- (void)terminate;

// (mpv_handle *)playerHandle;
- (void *)playerHandle;

- (void)startPlayback;
- (void)pausePlayback;

- (void)frameStepBack;
- (void)frameStepForward;

@end
