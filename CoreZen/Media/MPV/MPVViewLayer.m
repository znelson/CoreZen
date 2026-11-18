//
//  MPVViewLayer.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVViewLayer.h"
#import "MPVRenderController.h"
#import "MPVFunctions.h"
#import "MediaPlayerView+Private.h"

@import QuartzCore.CATransaction;

@interface ZENMPVViewLayer ()

// Something other than a new mpv frame needs the layer redrawn, for example the view
// appearing or being resized. Core Animation only calls canDrawInCGLContext: once the
// layer can actually draw, so a request made while it's off screen waits until then.
@property (atomic) BOOL redrawRequested;

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
	CGLRetainContext(context);
	return context;
}

- (void)setNeedsDisplay {
	self.redrawRequested = YES;
	[super setNeedsDisplay];
}

- (BOOL)canDrawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
	ZENMPVRenderController *renderController = self.playerView.renderController;
	if (!renderController.hasRenderContext) {
		return NO;
	}

	// Always ask mpv, which clears its new frame flag. Without a new frame, a redraw
	// renders mpv's current frame again, such as the one a paused player is showing.
	BOOL newFrame = renderController.readyToRenderFrame;
	BOOL redraw = self.redrawRequested;
	self.redrawRequested = NO;
	return newFrame || redraw;
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
	[self.playerView.renderController renderNextFrame];
}

- (void)display {
	[super display];
	[CATransaction flush];
}

@end
