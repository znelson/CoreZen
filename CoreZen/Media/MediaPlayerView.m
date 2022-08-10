//
//  MediaPlayerView.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MediaPlayerView.h"
#import "MediaPlayer.h"
#import "MPVRenderController.h"
#import "MPVViewLayer.h"

@interface ZENMediaPlayer ()
- (void)attachPlayerView:(ZENMediaPlayerView *)view;
@end

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

- (void)awakeFromNib {
	[super awakeFromNib];
	[self initCommon];
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	if (self.player) {
		[self.renderController createRenderContextForPlayer:self.player];
	}
}

- (BOOL)mouseDownCanMoveWindow {
	return YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	[player attachPlayerView:self];
	if (self.player) {
		[self.renderController createRenderContextForPlayer:self.player];
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
