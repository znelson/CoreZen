//
//  MediaPlayerView.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MediaPlayerView+Private.h"
#import "MediaPlayer+Private.h"
#import "MPVRenderController.h"
#import "MPVViewLayer.h"

@interface ZENMediaPlayerView ()

- (void)setupCommon;

// Redraw the current frame, which mpv doesn't send again while it's paused
- (void)requestRedraw;
- (void)windowDidChangeOcclusionState:(NSNotification *)notification;

@end

@implementation ZENMediaPlayerView

- (void)setupCommon {
	ZENMPVViewLayer *viewLayer = [ZENMPVViewLayer new];
	viewLayer.playerView = self;

	_renderController = [[ZENMPVRenderController alloc] initWithPlayerView:self];

	NSOpenGLPixelFormatAttribute pixelFormatAttrs[] = {
		NSOpenGLPFAAllowOfflineRenderers,
		NSOpenGLPFAAccelerated,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
		0
	};
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelFormatAttrs];

	self.pixelFormat = pixelFormat;
	self.layer = viewLayer;
	self.layer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
	self.wantsLayer = YES;
	self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	self.wantsBestResolutionOpenGLSurface = YES;
	self.wantsExtendedDynamicRangeOpenGLSurface = YES;
	self.canDrawConcurrently = YES;
}

- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format {
	self = [super initWithFrame:frameRect pixelFormat:format];
	if (self) {
		[self setupCommon];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self setupCommon];
	}
	return self;
}

- (void)dealloc {
	[NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)requestRedraw {
	[self.layer setNeedsDisplay];
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	[super viewWillMoveToWindow:newWindow];
	if (self.window) {
		[NSNotificationCenter.defaultCenter removeObserver:self name:NSWindowDidChangeOcclusionStateNotification object:self.window];
	}
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	if (self.player) {
		[self.renderController createRenderContext];
	}
	if (self.window) {
		// A window is often set up before it's on screen, as at app launch, and the
		// layer can only draw once it is
		[NSNotificationCenter.defaultCenter addObserver:self
											   selector:@selector(windowDidChangeOcclusionState:)
												   name:NSWindowDidChangeOcclusionStateNotification
												 object:self.window];
		[self requestRedraw];
	}
}

- (void)windowDidChangeOcclusionState:(NSNotification *)notification {
	[self requestRedraw];
}

- (void)setFrameSize:(NSSize)newSize {
	[super setFrameSize:newSize];
	[self requestRedraw];
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	if (!player || player == self.player) {
		return;
	}

	// The render context belongs to one player's mpv instance, and mpv allows
	// one render context per instance. Let go of this view's current player,
	// and take the new player away from any other view it's attached to.
	[self detachPlayer];
	[player.playerView detachPlayer];

	self.player = player;
	[player attachPlayerView:self];
	[self.renderController createRenderContext];
	[self requestRedraw];
}

- (void)detachPlayer {
	if (self.player) {
		[self.player detachPlayerView];
		[self terminatePlayerView];
	}
}

- (void)terminatePlayerView {
	if (self.player) {
		[self.renderController destroyRenderContext];
		self.player = nil;
	}
}

- (void)lockViewContext {
	[self.openGLContext makeCurrentContext];
	CGLLockContext(self.openGLContext.CGLContextObj);
	CGLSetCurrentContext(self.openGLContext.CGLContextObj);
}

- (void)unlockViewContext {
	CGLUnlockContext(self.openGLContext.CGLContextObj);
}

@end
