//
//  FrameRendererTypes.h
//  CoreZen
//
//  Created by Zach Nelson on 11/10/22.
//

#import <Foundation/Foundation.h>

@class ZENRenderedFrame;

// Completion block types
typedef void (^ZENRenderFrameResultsBlock)(ZENRenderedFrame *frame);
typedef void (^ZENRenderFramesResultsBlock)(NSArray<ZENRenderedFrame *> *frames);
