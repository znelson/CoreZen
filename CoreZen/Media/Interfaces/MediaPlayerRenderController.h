//
//  MediaPlayerRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayer;

@protocol ZENMediaPlayerRenderController <NSObject>

- (void)createRenderContext;
- (void)destroyRenderContext;

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

@end
