//
//  FrameRenderer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <CoreZen/FrameRenderer.h>

@class ZENLibAVRenderController;

@interface ZENFrameRenderer ()

@property (nonatomic, strong, readonly) ZENLibAVRenderController *frameRenderController;

@end
