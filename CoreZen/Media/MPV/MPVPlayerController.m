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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

static uint64_t zen_mpv_next_observer_identifier(void);
static void zen_mpv_wakeup(void *ctx);

@interface ZENMPVPlayerController ()
{
	uint64_t _observerID;
	mpv_handle *_mpvHandle;
	
@public
	dispatch_queue_t _eventQueue;
}

@property (nonatomic, strong, readonly) NSThread *mpvEventThread;

- (void)observeProperties;
- (void)mpvHandleEvents;

@end

@implementation ZENMPVPlayerController

- (instancetype)initWithPlayer:(ZENMediaPlayer *)player {
	self = [super init];
	if (self) {
		_player = player;
		
		_observerID = zen_mpv_next_observer_identifier();
		
		dispatch_queue_attr_t qos = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0);
		_eventQueue = dispatch_queue_create("com.zdnelson.CoreZen.mpv-player", qos);
		
		_mpvHandle = mpv_create();
		
		_clientName = zen_mpv_string(mpv_client_name(_mpvHandle));
		
		mpv_set_option_string(_mpvHandle, kMPVOption_hwdec, kMPVParam_videotoolbox);
		mpv_set_option_string(_mpvHandle, kMPVOption_vo, kMPVParam_libmpv);
		
		mpv_request_log_messages(_mpvHandle, "warn");
		
		mpv_initialize(_mpvHandle);
		
		_version = zen_mpv_string(mpv_get_property_string(_mpvHandle, kMPVProperty_mpv_version));
		
		void *selfAsVoid = (__bridge void *)self;
		mpv_set_wakeup_callback(_mpvHandle, zen_mpv_wakeup, selfAsVoid);
		
		const char* loadCommand[] = {
			"loadfile",
			player.fileURL.path.fileSystemRepresentation,
			"append",
			nil
		};
		mpv_command(_mpvHandle, loadCommand);

		const char* playCommand[] = {
			"playlist-play-index",
			"0",
			nil
		};
		mpv_command(_mpvHandle, playCommand);
		
		[self observeProperties];

		[self pausePlayback];
	}
	return self;
}

- (void)dealloc {
	mpv_unobserve_property(_mpvHandle, _observerID);

	mpv_set_wakeup_callback(_mpvHandle, zen_mpv_wakeup, nil);

	dispatch_sync(_eventQueue, ^{});
	
	mpv_destroy(_mpvHandle);
}

- (void)observeProperties {
	mpv_observe_property(_mpvHandle, _observerID, kMPVProperty_percent_pos, MPV_FORMAT_NODE);
	mpv_observe_property(_mpvHandle, _observerID, kMPVProperty_pause, MPV_FORMAT_NODE);
}
	
- (void *)playerHandle {
	return _mpvHandle;
}

- (void)startPlayback {
	zen_mpv_set_bool_property(_mpvHandle, kMPVProperty_pause, NO);
}

- (void)pausePlayback {
	zen_mpv_set_bool_property(_mpvHandle, kMPVProperty_pause, YES);
}

- (void)mpvHandleEvents {
	while (true) {
		mpv_event *event = mpv_wait_event(_mpvHandle, 0);
		if (event->event_id == MPV_EVENT_NONE) {
			// MPV_EVENT_NONE means the event queue is empty, meaning we
			// can break out of the outer loop and let this thread return
			break;
		}
		switch (event->event_id) {
			case MPV_EVENT_SHUTDOWN: {
				NSLog(@"MPV_EVENT_SHUTDOWN");
				break;
			}
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
				break;
			}
			case MPV_EVENT_PLAYBACK_RESTART: {
				NSLog(@"MPV_EVENT_PLAYBACK_RESTART");
				break;
			}
			case MPV_EVENT_PROPERTY_CHANGE: {
				mpv_event_property *property = event->data;

				mpv_node node = {};
				if (mpv_event_to_node(&node, event) == MPV_ERROR_SUCCESS) {

					// Example node map for "pause" property change:
					// {
					// 	"event": "property-change",
					// 	"id": 1,						// _observerID
					// 	"name": "pause",
					// 	"data": 0						// Flag value for "pause" property
					// }

					const char* propertyName = nil;
					mpv_node *propertyValueNode = nil;
					uint64_t propertyID = 0;

					if (node.format == MPV_FORMAT_NODE_MAP) {
						mpv_node_list *nodeList = node.u.list;
						for (int nodeIndex = 0; nodeIndex < nodeList->num; ++nodeIndex) {
							char *mapKey = *(nodeList->keys + nodeIndex);
							mpv_node *mapNode = nodeList->values + nodeIndex;

							if (zen_mpv_compare_strings(kMPVPropertyKey_name, mapKey)) {
								propertyName = mapNode->u.string;
							} else if (zen_mpv_compare_strings(kMPVPropertyKey_data, mapKey)) {
								propertyValueNode = mapNode;
							} else if (zen_mpv_compare_strings(kMPVPropertyKey_id, mapKey)) {
								propertyID = mapNode->u.int64;
							}
						}
					}
					
					NSLog(@"MPV_EVENT_PROPERTY_CHANGE (%llu): %s", propertyID, property->name);

					if (propertyName && propertyValueNode && propertyID == _observerID) {
						if (zen_mpv_compare_strings(kMPVProperty_pause, propertyName)) {
							BOOL paused = (BOOL)propertyValueNode->u.flag;
							self.player.paused = paused;
							NSLog(@"Paused: %d", paused);
						} else if (zen_mpv_compare_strings(kMPVProperty_percent_pos, propertyName)) {
							double percentPos = propertyValueNode->u.double_;
							NSLog(@"Position: %f", percentPos);
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

static uint64_t zen_mpv_next_observer_identifier(void) {
	static atomic_uint_fast64_t nextIdentifier = 1;
	return atomic_fetch_add(&nextIdentifier, 1);
}

static void zen_mpv_wakeup(void *ctx) {
	__unsafe_unretained ZENMPVPlayerController *controller = (__bridge ZENMPVPlayerController *)ctx;
	dispatch_async(controller->_eventQueue, ^{
		[controller mpvHandleEvents];
	});
}
