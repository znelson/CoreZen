//
//  FrameRenderController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRendererTypes.h>

@protocol ZENFrameRenderController <NSObject>

- (void)terminate;

- (void)renderFrame:(ZENRenderedFrame *)frame
			   size:(NSSize)size
		 completion:(ZENFrameRendererResultsBlock)completion;

@end
