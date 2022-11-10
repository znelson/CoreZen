//
//  MediaPlayerController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@protocol ZENMediaPlayerController <NSObject, ZENIdentifiable>

- (void)terminate;

// (mpv_handle *)playerHandle;
- (void *)playerHandle;

- (void)startPlayback;
- (void)pausePlayback;

- (void)frameStepBack;
- (void)frameStepForward;

- (void)seekBySeconds:(double)seconds;

@end
