//
//  MediaPlayerController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import <Foundation/Foundation.h>

@protocol ZENMediaPlayerController <NSObject>

// (mpv_handle *)playerHandle;
- (void *)playerHandle;

- (void)startPlayback;

@end
