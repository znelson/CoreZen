//
//  MPVViewLayer.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVViewLayer.h"
#import "MPVRenderController.h"
#import "MPVFunctions.h"
#import "MediaPlayerView.h"

@import QuartzCore.CATransaction;

@interface ZENMPVViewLayer ()

@end

@implementation ZENMPVViewLayer

- (instancetype)init {
	self = [super init];
	if (self) {
		self.opaque = YES;
		self.asynchronous = NO;
		self.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	}
	return self;
}

- (CGLPixelFormatObj)copyCGLPixelFormatForDisplayMask:(uint32_t)mask {
	CGLPixelFormatObj pixelFormat;
	GLint pixelFormatCount = 0;
	CGLPixelFormatAttribute attributes[] = {
		kCGLPFAAllowOfflineRenderers,
		kCGLPFAAccelerated,
		kCGLPFADoubleBuffer,
		kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_3_2_Core,
		0
	};
	CGLChoosePixelFormat(attributes, &pixelFormat, &pixelFormatCount);
	return pixelFormat;
}

- (CGLContextObj)copyCGLContextForPixelFormat:(CGLPixelFormatObj)pf {
	CGLContextObj context = self.playerView.openGLContext.CGLContextObj;
	
	// https://developer.apple.com/library/archive/documentation/GraphicsImaging/Conceptual/OpenGL-MacProgGuide/opengl_contexts/opengl_contexts.html
	// If the swap interval is set to 0 (the default), buffers are swapped as soon as possible, without regard to the vertical refresh rate of the monitor.
	// If the swap interval is set to any other value, the buffers are swapped only during the vertical retrace of the monitor.
	static GLint sync = 1;
	CGLSetParameter(context, kCGLCPSwapInterval, &sync);
	
	CGLSetCurrentContext(context);
	return context;
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
	return self.playerView.renderController.readyToRenderFrame;
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
	[self.playerView.renderController renderNextFrame];
}

- (void)display {
	[super display];
	[CATransaction flush];
}

@end
