//
//  FrameRenderer+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <CoreZen/FrameRenderer.h>

@protocol ZENFrameRenderController;

@interface ZENFrameRenderer ()

@property (nonatomic, strong, readonly) NSObject<ZENFrameRenderController> *frameRenderController;

@end
