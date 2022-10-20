//
//  MPVRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/MediaPlayerRenderController.h>

@class ZENMediaPlayerView;

@interface ZENMPVRenderController : NSObject <ZENMediaPlayerRenderController>

- (instancetype)initWithPlayerView:(ZENMediaPlayerView *)playerView;

@property (nonatomic, weak, readonly) ZENMediaPlayerView *playerView;

// ZENMediaPlayerRenderController protocol
- (void)createRenderContext;
- (void)destroyRenderContext;

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

@end
