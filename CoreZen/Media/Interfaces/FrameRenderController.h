//
//  FrameRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRendererTypes.h>
#import <CoreZen/WorkQueueTypes.h>

@protocol ZENFrameRenderController <NSObject>

- (void)terminate;

- (ZENCancelToken *)renderFrame:(ZENRenderedFrame *)renderedFrame
						   size:(NSSize)size
					 completion:(ZENRenderFrameResultsBlock)completion;

@end
