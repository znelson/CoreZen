//
//  MPVController.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MPVController.h"
#import "MPVFunctions.h"
#import "MediaPlayer.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

static void zen_mpv_wakeup(void *ctx);

@interface ZENMPVController ()
{
	mpv_handle *_mpvHandle;
	
@public
	dispatch_queue_t _eventQueue;
}

@property (nonatomic, strong, readonly) NSThread *mpvEventThread;

- (void)mpvHandleEvents;

@end

@implementation ZENMPVController

- (instancetype)initWithPlayer:(ZENMediaPlayer *)player {
	self = [super init];
	if (self) {
		_player = player;
		
		dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
		_eventQueue = dispatch_queue_create("com.zdnelson.CoreZen.MPVController", qos);
		
		_mpvHandle = mpv_create();
		
		_clientName = zen_mpv_string(mpv_client_name(_mpvHandle));
		
		mpv_set_option_string(_mpvHandle, "hwdec", "videotoolbox");
		mpv_set_option_string(_mpvHandle, "vo", "libmpv");
		
		mpv_request_log_messages(_mpvHandle, "warn");
		
		mpv_initialize(_mpvHandle);
		
		_version = zen_mpv_string(mpv_get_property_string(_mpvHandle, "mpv-version"));
		
		void *selfAsVoid = (__bridge void *)self;
		mpv_set_wakeup_callback(_mpvHandle, zen_mpv_wakeup, selfAsVoid);
		
		const char* command[] = {
			"loadfile",
			player.fileURL.path.fileSystemRepresentation,
			"append",
			nil
		};
		mpv_command(_mpvHandle, command);
	}
	return self;
}

- (void)dealloc {
	dispatch_sync(_eventQueue, ^{});
	mpv_destroy(_mpvHandle);
}
	
- (void *)playerHandle {
	return _mpvHandle;
}

- (void)startPlayback {
	const char* command[] = {
		"playlist-play-index",
		"0",
		nil
	};
	mpv_command(_mpvHandle, command);
}

- (void)mpvHandleEvents {
	mpv_event *event = mpv_wait_event(_mpvHandle, 0);
	switch (event->event_id) {
		case MPV_EVENT_NONE: {
			NSLog(@"MPV_EVENT_NONE");
			break;
		}
		case MPV_EVENT_SHUTDOWN: {
			NSLog(@"MPV_EVENT_SHUTDOWN");
			break;
		}
		case MPV_EVENT_LOG_MESSAGE: {
			struct mpv_event_log_message *msg = event->data;
			NSLog(@"MPV_EVENT_LOG_MESSAGE: [%s] <%s> %s", msg->prefix, msg->level, msg->text);
			break;
		}
		case MPV_EVENT_GET_PROPERTY_REPLY: {
			NSLog(@"MPV_EVENT_GET_PROPERTY_REPLY");
			break;
		}
		case MPV_EVENT_SET_PROPERTY_REPLY: {
			NSLog(@"MPV_EVENT_SET_PROPERTY_REPLY");
			break;
		}
		case MPV_EVENT_COMMAND_REPLY: {
			NSLog(@"MPV_EVENT_COMMAND_REPLY");
			break;
		}
		case MPV_EVENT_START_FILE: {
			NSLog(@"MPV_EVENT_START_FILE");
			break;
		}
		case MPV_EVENT_END_FILE: {
			NSLog(@"MPV_EVENT_END_FILE");
			break;
		}
		case MPV_EVENT_FILE_LOADED: {
			NSLog(@"MPV_EVENT_FILE_LOADED");
			break;
		}
		case MPV_EVENT_TRACKS_CHANGED: {
			NSLog(@"MPV_EVENT_TRACKS_CHANGED");
			break;
		}
		case MPV_EVENT_TRACK_SWITCHED: {
			NSLog(@"MPV_EVENT_TRACK_SWITCHED");
			break;
		}
		case MPV_EVENT_IDLE: {
			NSLog(@"MPV_EVENT_IDLE");
			break;
		}
		case MPV_EVENT_PAUSE: {
			NSLog(@"MPV_EVENT_PAUSE");
			break;
		}
		case MPV_EVENT_UNPAUSE: {
			NSLog(@"MPV_EVENT_UNPAUSE");
			break;
		}
		case MPV_EVENT_TICK: {
			NSLog(@"MPV_EVENT_TICK");
			break;
		}
		case MPV_EVENT_SCRIPT_INPUT_DISPATCH: {
			NSLog(@"MPV_EVENT_SCRIPT_INPUT_DISPATCH");
			break;
		}
		case MPV_EVENT_CLIENT_MESSAGE: {
			NSLog(@"MPV_EVENT_CLIENT_MESSAGE");
			break;
		}
		case MPV_EVENT_VIDEO_RECONFIG: {
			NSLog(@"MPV_EVENT_VIDEO_RECONFIG");
			break;
		}
		case MPV_EVENT_AUDIO_RECONFIG: {
			NSLog(@"MPV_EVENT_AUDIO_RECONFIG");
			break;
		}
		case MPV_EVENT_METADATA_UPDATE: {
			NSLog(@"MPV_EVENT_METADATA_UPDATE");
			break;
		}
		case MPV_EVENT_SEEK: {
			NSLog(@"MPV_EVENT_SEEK");
			break;
		}
		case MPV_EVENT_PLAYBACK_RESTART: {
			NSLog(@"MPV_EVENT_PLAYBACK_RESTART");
			break;
		}
		case MPV_EVENT_PROPERTY_CHANGE: {
			NSLog(@"MPV_EVENT_PROPERTY_CHANGE");
			break;
		}
		case MPV_EVENT_CHAPTER_CHANGE: {
			NSLog(@"MPV_EVENT_CHAPTER_CHANGE");
			break;
		}
		case MPV_EVENT_QUEUE_OVERFLOW: {
			NSLog(@"MPV_EVENT_QUEUE_OVERFLOW");
			break;
		}
		case MPV_EVENT_HOOK: {
			NSLog(@"MPV_EVENT_HOOK");
			break;
		}
	}
}

@end

static void zen_mpv_wakeup(void *ctx) {
	__unsafe_unretained ZENMPVController *controller = (__bridge ZENMPVController *)ctx;
	dispatch_async(controller->_eventQueue, ^{
		[controller mpvHandleEvents];
	});
}
