//
//  FrameRenderer.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>

@protocol ZENFrameRenderController;

@interface ZENFrameRenderer : NSObject

- (instancetype)initWithController:(NSObject<ZENFrameRenderController> *)controller;

@end
