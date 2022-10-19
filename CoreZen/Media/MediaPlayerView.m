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

- (void)initCommon;

@end

@implementation ZENMediaPlayerView

- (void)initCommon {
	ZENMPVViewLayer *viewLayer = [ZENMPVViewLayer new];
	viewLayer.playerView = self;
	
	_renderController = [[ZENMPVRenderController new] initWithPlayerView:self];
	
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
		[self initCommon];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self initCommon];
	}
	return self;
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	if (self.player) {
		[self.renderController createRenderContext];
	}
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	if (player) {
		self.player = player;
		[player attachPlayerView:self];
		[self.renderController createRenderContext];
	}
}

- (void)detachPlayer {
	if (self.player) {
		[self.player detachPlayerView];
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
