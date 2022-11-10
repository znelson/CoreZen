//
//  FrameRenderer.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/FrameRendererTypes.h>

// Rendered frame result
@interface ZENRenderedFrame : NSObject

// The rendered video frame image
@property (nonatomic, strong) NSImage *image;

// The requested position of the frame
@property (nonatomic) int64_t requestedTimestamp;
@property (nonatomic) double requestedSeconds;
@property (nonatomic) double requestedPercentage;

// The actual rendered position of the frame
@property (nonatomic) int64_t actualTimestamp;
@property (nonatomic) double actualSeconds;
@property (nonatomic) double actualPercentage;

@end

@protocol ZENFrameRenderController;

// Interface for requesting rendered frames
@interface ZENFrameRenderer : NSObject

- (instancetype)initWithController:(NSObject<ZENFrameRenderController> *)controller;

- (void)renderFrameAtSeconds:(double)seconds
					   width:(NSUInteger)width
					  height:(NSUInteger)height
				  completion:(ZENFrameRendererResultsBlock)completion;

- (void)renderFrameAtPercentage:(double)percentage
						  width:(NSUInteger)width
						 height:(NSUInteger)height
					 completion:(ZENFrameRendererResultsBlock)completion;

@end
