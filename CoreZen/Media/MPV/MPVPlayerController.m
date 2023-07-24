//
//  MPVPlayerController.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MPVPlayerController.h"
#import "MPVFunctions.h"
#import "MPVConstants.h"
#import "MediaPlayer+Private.h"

#import <stdatomic.h>

@import Darwin.POSIX.pthread;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

static void zen_mpv_wakeup(void *ctx);

@interface ZENMPVPlayerController ()
{
	mpv_handle *_mpvHandle;
	
	BOOL _terminated;
	
	pthread_mutex_t _playerMutex;
	pthread_cond_t _playerCondition;
	
@public
	dispatch_queue_t _eventQueue;
}

- (void)destroyHandle;
- (void)mpvHandleEvents;

- (void)mpvCommand:(const char** const)command;
- (void)mpvSimpleCommand:(const char* const)command;

@end

@implementation ZENMPVPlayerController

@synthesize identifier=_identifier;

- (void)mpvCommand:(const char** const)command {
	mpv_command(_mpvHandle, command);
}

- (void)mpvSimpleCommand:(const char* const)command {
	const char* cmd[] = { command, nil };
	[self mpvCommand:cmd];
}

- (instancetype)initWithPlayer:(ZENMediaPlayer *)player {
	self = [super init];
	if (self) {
		_player = player;
		
		static atomic_uint_fast64_t nextIdentifier = 1;
		_identifier = atomic_fetch_add(&nextIdentifier, 1);
		
		_terminated = NO;
		
		// Initialize mutex and condition variable
		zen_mpv_init_pthread_mutex_cond(&_playerMutex, &_playerCondition);
		
		// Initialize MPV player event serial queue
		dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
		_eventQueue = dispatch_queue_create("ZENMediaPlayer.mpv-player", qos);
		
		// Create MPV handle (initialization happens after configuration)
		_mpvHandle = mpv_create();
		
		_clientName = zen_mpv_to_nsstring(mpv_client_name(_mpvHandle));
		
		// Set MPV configuration
		mpv_set_option_string(_mpvHandle, kMPVOption_hwdec, kMPVOptionParam_videotoolbox);
		mpv_set_option_string(_mpvHandle, kMPVOption_vo, kMPVOptionParam_libmpv);
		
		mpv_request_log_messages(_mpvHandle, "warn");
		
		// Initialize MPV handle
		mpv_initialize(_mpvHandle);
		
		_version = zen_mpv_to_nsstring(mpv_get_property_string(_mpvHandle, kMPVProperty_mpv_version));
		
		// Disable subtitles
		zen_mpv_set_string_property(_mpvHandle, kMPVProperty_sid, kMPVPropertyKey_no);
		
		// Set event callback function
		void *selfAsVoid = (__bridge void *)self;
		mpv_set_wakeup_callback(_mpvHandle, zen_mpv_wakeup, selfAsVoid);
		
		// Observe properties
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_percent_pos, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_pause, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_path, MPV_FORMAT_NODE);
	}
	return self;
}

- (void)terminate {
	mpv_unobserve_property(_mpvHandle, self.identifier);
	
	NSLog(@"Terminating mpv player queue...");
	
	// Send a mpv quit command, which will trigger MPV_EVENT_SHUTDOWN
	[self mpvSimpleCommand:kMPVCommand_quit];

	// Wait for MPV_EVENT_SHUTDOWN to call -destroyHandle which sets _terminated to YES
	pthread_mutex_lock(&_playerMutex);
	while (!_terminated) {
		pthread_cond_wait(&_playerCondition, &_playerMutex);
	}
	pthread_mutex_unlock(&_playerMutex);
	
	NSLog(@"Finished terminating mpv player queue");
	
	// Clean up mutex and condition variable
	zen_mpv_destroy_pthread_mutex_cond(&_playerMutex, &_playerCondition);
}

- (void)destroyHandle {
	// Remove property observers
	mpv_unobserve_property(_mpvHandle, self.identifier);
	
	// Remove event callback function
	mpv_set_wakeup_callback(_mpvHandle, nil, nil);
	
	// Destroy MPV handle
	mpv_destroy(_mpvHandle);
	_mpvHandle = nil;
	
	// Set _terminated flag and signal waiting thread
	pthread_mutex_lock(&_playerMutex);
	_terminated = YES;
	pthread_cond_signal(&_playerCondition);
	pthread_mutex_unlock(&_playerMutex);
}
	
- (void *)playerHandle {
	return _mpvHandle;
}

- (void)openFileURL:(NSURL *)url {
	const char* loadCommand[] = {
		kMPVCommand_loadfile,
		url.path.fileSystemRepresentation,
		kMPVCommandParam_replace,
		nil
	};
	[self mpvCommand:loadCommand];
	
	[self pausePlayback];
}

- (void)startPlayback {
	zen_mpv_set_bool_property(_mpvHandle, kMPVProperty_pause, NO);
}

- (void)pausePlayback {
	zen_mpv_set_bool_property(_mpvHandle, kMPVProperty_pause, YES);
}

- (void)frameStepBack {
	[self mpvSimpleCommand:kMPVCommand_frame_back_step];
}

- (void)frameStepForward {
	[self mpvSimpleCommand:kMPVCommand_frame_step];
}

- (void)seekBySeconds:(double)seconds {
	const char* command[] = {
		kMPVCommand_seek,
		zen_double_to_mpv_string(seconds),
		kMPVCommandParam_relative,
		nil
	};
	[self mpvCommand:command];
}

- (void)seekToSeconds:(double)seconds {
	const char* command[] = {
		kMPVCommand_seek,
		zen_double_to_mpv_string(seconds),
		kMPVCommandParam_absolute,
		nil
	};
	[self mpvCommand:command];
}

- (void)seekToPercentage:(double)percentage {
	const char* command[] = {
		kMPVCommand_seek,
		zen_double_to_mpv_string(percentage),
		kMPVCommandParam_absolute_percent,
		nil
	};
	[self mpvCommand:command];
}

- (void)mpvHandleEvents {
	while (true) {
		mpv_event *event = mpv_wait_event(_mpvHandle, 0);
		mpv_event_id eid = event->event_id;
		
		if (eid == MPV_EVENT_NONE) {
			// MPV_EVENT_NONE means the event queue is empty, meaning we
			// can break out of the outer loop and let this thread return
			break;
		} else if (eid == MPV_EVENT_SHUTDOWN) {
			NSLog(@"MPV_EVENT_SHUTDOWN");
			[self destroyHandle];
			break;
		}
		switch (eid) {
			case MPV_EVENT_LOG_MESSAGE: {
				mpv_event_log_message *msg = event->data;
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
			case MPV_EVENT_SEEK: {
				NSLog(@"MPV_EVENT_SEEK");
				dispatch_async(dispatch_get_main_queue(), ^{
					self.player.seeking = YES;
				});
				break;
			}
			case MPV_EVENT_PLAYBACK_RESTART: {
				NSLog(@"MPV_EVENT_PLAYBACK_RESTART");
				dispatch_async(dispatch_get_main_queue(), ^{
					self.player.seeking = NO;
				});
				break;
			}
			case MPV_EVENT_PROPERTY_CHANGE: {
				mpv_node node = {};
				if (mpv_event_to_node(&node, event) == MPV_ERROR_SUCCESS) {

					// Example node map for "pause" property change:
					// {
					// 	"event": "property-change",
					// 	"id": 1,						// self.identifier
					// 	"name": "pause",
					// 	"data": 0						// Flag value for "pause" property
					// }

					const char* propertyName = nil;
					mpv_node *valueNode = nil;
					uint64_t observerID = 0;

					if (node.format == MPV_FORMAT_NODE_MAP) {
						mpv_node_list *nodeList = node.u.list;
						for (int nodeIndex = 0; nodeIndex < nodeList->num; ++nodeIndex) {
							char *mapKey = *(nodeList->keys + nodeIndex);
							mpv_node *mapNode = nodeList->values + nodeIndex;

							if (zen_mpv_compare_strings(kMPVPropertyKey_name, mapKey)) {
								propertyName = mapNode->u.string;
							} else if (zen_mpv_compare_strings(kMPVPropertyKey_data, mapKey)) {
								valueNode = mapNode;
							} else if (zen_mpv_compare_strings(kMPVPropertyKey_id, mapKey)) {
								observerID = mapNode->u.int64;
							}
						}
					}
					
					// mpv_event_property *property = event->data;
					// NSLog(@"MPV_EVENT_PROPERTY_CHANGE (%llu): %s", observerID, property->name);

					if (propertyName && valueNode && observerID == self.identifier) {
						if (zen_mpv_compare_strings(kMPVProperty_pause, propertyName)) {
							BOOL paused = (BOOL)valueNode->u.flag;
							// NSLog(@"Paused: %d", paused);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.paused = paused;
							});
						} else if (zen_mpv_compare_strings(kMPVProperty_percent_pos, propertyName)) {
							double percentPos = valueNode->u.double_;
							// NSLog(@"Position: %f", percentPos);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.positionPercent = percentPos;
							});
						} else if (zen_mpv_compare_strings(kMPVProperty_path, propertyName)) {
							NSString *path = zen_mpv_to_nsstring(valueNode->u.string);
							NSURL *url = [NSURL fileURLWithPath:path];
							// NSLog(@"Path: %@", url);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.fileURL = url;
							});
						}
					}

					mpv_free_node_contents(&node);
				}			

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
			default: {
				break;
			}
		}
	}
}

@end

static void zen_mpv_wakeup(void *ctx) {
	__unsafe_unretained ZENMPVPlayerController *controller = (__bridge ZENMPVPlayerController *)ctx;
	dispatch_async(controller->_eventQueue, ^{
		[controller mpvHandleEvents];
	});
}
