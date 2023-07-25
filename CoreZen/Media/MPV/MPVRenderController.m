//
//  MPVRenderController.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVPlayerController.h"
#import "MPVRenderController.h"
#import "MPVFunctions.h"
#import "MediaPlayer+Private.h"
#import "MediaPlayerView+Private.h"

@import Darwin.POSIX.pthread;
@import OpenGL.GL;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/render_gl.h>

#pragma clang diagnostic pop

static void zen_mpv_render_context_update(void *ctx);

@interface ZENMPVRenderController ()
{
	mpv_render_context *_mpvRenderContext;
	
	mpv_opengl_fbo _mpvFBO;
	mpv_render_param _mpvRenderParams[3];
	mpv_render_param _mpvSkipRenderParams[2];
	
	BOOL _didRenderFrame;
	BOOL _forceRenderFrame;
	BOOL _terminated;
	
	pthread_mutex_t _renderMutex;
	pthread_cond_t _renderCondition;
	
@public
	dispatch_queue_t _renderQueue;
}

- (mpv_handle *)mpvHandleFromPlayerView;

- (void)initRenderContext;

- (void)renderFrameOnRenderQueue;

@end

@implementation ZENMPVRenderController

- (instancetype)initWithPlayerView:(ZENMediaPlayerView *)playerView {
	self = [super init];
	if (self) {
		_playerView = playerView;
		_didRenderFrame = NO;
		_forceRenderFrame = NO;
		_terminated = NO;
		
		zen_mpv_init_pthread_mutex_cond(&_renderMutex, &_renderCondition);
		
		dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
		_renderQueue = dispatch_queue_create("ZENMediaPlayer.mpv-render", qos);
		
		NSSize playerViewSize = playerView.frame.size;
		_mpvFBO = (mpv_opengl_fbo) { .fbo = 1, .w = playerViewSize.width, .h = playerViewSize.height };
		
		static int flipY = 1;
		_mpvRenderParams[0] = (mpv_render_param) { .type = MPV_RENDER_PARAM_OPENGL_FBO, .data = &_mpvFBO };
		_mpvRenderParams[1] = (mpv_render_param) { .type = MPV_RENDER_PARAM_FLIP_Y, .data = &flipY };
		_mpvRenderParams[2] = (mpv_render_param) {};
		
		static int skip = 1;
		_mpvSkipRenderParams[0] = (mpv_render_param) { .type = MPV_RENDER_PARAM_SKIP_RENDERING, .data = &skip };
		_mpvSkipRenderParams[1] = (mpv_render_param) {};
	}
	return self;
}

- (void)dealloc {
	if (_mpvRenderContext) {
		[self destroyRenderContext];
	}
}

- (mpv_handle *)mpvHandleFromPlayerView {
	mpv_handle *mpvHandle = self.playerView.player.playerController.playerHandle;
	return mpvHandle;
}

- (void)initRenderContext {
	
	void *selfAsVoid = (__bridge void *)self;
	
	mpv_opengl_init_params glParams = {
		.get_proc_address = zen_mpv_get_opengl_proc_address,
		.get_proc_address_ctx = selfAsVoid
	};
	
	mpv_render_param renderParams[] = {
		{ .type = MPV_RENDER_PARAM_API_TYPE, .data = MPV_RENDER_API_TYPE_OPENGL },
		{ .type = MPV_RENDER_PARAM_OPENGL_INIT_PARAMS, .data = &glParams },
		{}
	};
	
	[self.playerView lockViewContext];
	
	__unused int error = mpv_render_context_create(&_mpvRenderContext, self.mpvHandleFromPlayerView, renderParams);
	
	mpv_render_context_set_update_callback(_mpvRenderContext, zen_mpv_render_context_update, selfAsVoid);
	
	[self.playerView unlockViewContext];
}

- (void)destroyRenderContext {
	mpv_render_context_set_update_callback(_mpvRenderContext, NULL, NULL);
	
	NSLog(@"Terminating mpv render queue...");
	
	pthread_mutex_lock(&_renderMutex);
	
	_terminated = YES;
	
	pthread_cond_signal(&_renderCondition);
	pthread_mutex_unlock(&_renderMutex);
	
	dispatch_sync(_renderQueue, ^{});
	
	NSLog(@"Finished terminating mpv render queue");
	
	zen_mpv_destroy_pthread_mutex_cond(&_renderMutex, &_renderCondition);
	
	mpv_render_context_free(_mpvRenderContext);
	_mpvRenderContext = nil;
}

- (void)createRenderContext {
	if (!_mpvRenderContext) {
		[self initRenderContext];
	}
}

- (BOOL)readyToRenderFrame {
	if (_mpvRenderContext) {
		pthread_mutex_lock(&_renderMutex);
		BOOL forceRenderFrame = _forceRenderFrame;
		pthread_mutex_unlock(&_renderMutex);
		
		if (forceRenderFrame) {
			return YES;
		}
		uint64_t flags = mpv_render_context_update(_mpvRenderContext);
		return (flags & MPV_RENDER_UPDATE_FRAME);
	}
	return NO;
}

- (void)renderNextFrame {
	
	[self.playerView lockViewContext];
	
	GLint frameBuffer = 0;
	glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &frameBuffer);
	
	GLint viewport[4] = {};
	glGetIntegerv(GL_VIEWPORT, viewport);
	
	_mpvFBO.fbo = frameBuffer;
	_mpvFBO.w = viewport[2];
	_mpvFBO.h = viewport[3];
	
	mpv_render_context_render(_mpvRenderContext, _mpvRenderParams);
	
	glClear(GL_COLOR_BUFFER_BIT);
	glFlush();
	
	[self.playerView unlockViewContext];
	
	pthread_mutex_lock(&_renderMutex);
	_didRenderFrame = YES;
	pthread_mutex_unlock(&_renderMutex);
}

- (void)renderFrameOnRenderQueue {
	
	// ZENMPVViewLayer -drawInCGLContext: calls back to -renderNextFrame to update _didRenderFrame
	
	pthread_mutex_lock(&_renderMutex);
	
	_didRenderFrame = NO;
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self.playerView.layer display];
		
		pthread_mutex_lock(&self->_renderMutex);
		pthread_cond_signal(&self->_renderCondition);
		pthread_mutex_unlock(&self->_renderMutex);
	});
	
	pthread_cond_wait(&_renderCondition, &_renderMutex);
	
	BOOL terminated = _terminated;
	BOOL didRenderFrame = _didRenderFrame;
	
	pthread_mutex_unlock(&_renderMutex);
	
	if (!terminated && !didRenderFrame) {
		[self.playerView lockViewContext];
		mpv_render_context_render(_mpvRenderContext, _mpvSkipRenderParams);
		[self.playerView unlockViewContext];
	}
}

@end

static void zen_mpv_render_context_update(void *ctx) {
	__unsafe_unretained ZENMPVRenderController *controller = (__bridge ZENMPVRenderController *)ctx;
	dispatch_async(controller->_renderQueue, ^{
		[controller renderFrameOnRenderQueue];
	});
}
