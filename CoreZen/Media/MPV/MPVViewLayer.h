//
//  MPVViewLayer.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Cocoa/Cocoa.h>

@class ZENMediaPlayerView;

@interface ZENMPVViewLayer : CAOpenGLLayer

@property (nonatomic, weak) ZENMediaPlayerView *playerView;

@end
