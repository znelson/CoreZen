//
//  MPVRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>

@class ZENMediaPlayerView;

@interface ZENMPVRenderController : NSObject

- (instancetype)initWithPlayerView:(ZENMediaPlayerView *)playerView;

@property (nonatomic, weak, readonly) ZENMediaPlayerView *playerView;

- (void)createRenderContext;
- (void)destroyRenderContext;

// YES while there's an mpv render context to draw with
@property (nonatomic, readonly) BOOL hasRenderContext;

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

// mpv frame updates handled so far, whether the view drew them or they were skipped
@property (atomic, readonly) NSUInteger frameUpdateCount;

@end
