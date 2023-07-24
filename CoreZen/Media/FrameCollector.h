//
//  FrameCollector.h
//  CoreZen
//
//  Created by Zach Nelson on 11/15/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRenderer.h>

@interface ZENFrameCollector : NSObject

+ (instancetype)frameCollectorWithCount:(NSUInteger)count
							 completion:(ZENRenderFramesResultsBlock)completion;

- (void)collect:(ZENRenderedFrame *)frame;

@end
