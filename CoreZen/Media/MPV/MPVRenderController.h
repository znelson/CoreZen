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

- (BOOL)readyToRenderFrame;
- (void)renderNextFrame;

@end
