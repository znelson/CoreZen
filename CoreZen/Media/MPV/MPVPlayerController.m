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

@interface ZENMPVPlayerController () {
	mpv_handle *_mpvHandle;

	BOOL _terminated;

	pthread_mutex_t _playerMutex;
	pthread_cond_t _playerCondition;

  @public
	dispatch_queue_t _eventQueue;
}

- (void)destroyHandle;
- (void)mpvHandleEvents;

- (int)mpvCommand:(const char **const)command;
- (void)mpvSimpleCommand:(const char *const)command;
- (ZENMPVCommandResult)mpvSeek:(double)target flags:(const char *const)flags;

@end

// A number property's value, or 0 while mpv has none, as when no file is loaded
static double ZENDoubleFromNode(const mpv_node *node) {
	if (node->format == MPV_FORMAT_DOUBLE) {
		return node->u.double_;
	}
	if (node->format == MPV_FORMAT_INT64) {
		return (double)node->u.int64;
	}
	return 0;
}

@implementation ZENMPVPlayerController

@synthesize identifier = _identifier;

- (int)mpvCommand:(const char **const)command {
	return mpv_command(_mpvHandle, command);
}

- (void)mpvSimpleCommand:(const char *const)command {
	const char *cmd[] = { command, nil };
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
		if (!_mpvHandle) {
			NSLog(@"ERROR: mpv_create() failed");
			return nil;
		}

		_clientName = zen_mpv_to_nsstring(mpv_client_name(_mpvHandle));

		// Set MPV configuration
		mpv_set_option_string(_mpvHandle, kMPVOption_hwdec, kMPVOptionParam_videotoolbox);
		mpv_set_option_string(_mpvHandle, kMPVOption_vo, kMPVOptionParam_libmpv);

		mpv_request_log_messages(_mpvHandle, "warn");

		// Initialize MPV handle
		mpv_initialize(_mpvHandle);

		char *version = mpv_get_property_string(_mpvHandle, kMPVProperty_mpv_version);
		_version = zen_mpv_to_nsstring(version);
		mpv_free(version);

		// Disable subtitles
		zen_mpv_set_string_property(_mpvHandle, kMPVProperty_sid, kMPVPropertyKey_no);

		// Set event callback function
		void *selfAsVoid = (__bridge void *)self;
		mpv_set_wakeup_callback(_mpvHandle, zen_mpv_wakeup, selfAsVoid);

		// Observe properties
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_percent_pos, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_pause, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_path, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_time_pos, MPV_FORMAT_NODE);
		mpv_observe_property(_mpvHandle, _identifier, kMPVProperty_duration, MPV_FORMAT_NODE);
	}
	return self;
}

- (void)terminate {
	mpv_unobserve_property(_mpvHandle, self.identifier);

	// Send a mpv quit command, which will trigger MPV_EVENT_SHUTDOWN
	[self mpvSimpleCommand:kMPVCommand_quit];

	// Wait for MPV_EVENT_SHUTDOWN to call -destroyHandle which sets _terminated to YES
	pthread_mutex_lock(&_playerMutex);
	while (!_terminated) {
		pthread_cond_wait(&_playerCondition, &_playerMutex);
	}
	pthread_mutex_unlock(&_playerMutex);

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

- (mpv_handle *)playerHandle {
	return _mpvHandle;
}

- (int64_t)openFileURL:(NSURL *)url failure:(NSString **)failure {
	const char *loadCommand[] = {
		kMPVCommand_loadfile,
		url.path.fileSystemRepresentation,
		kMPVCommandParam_replace,
		nil
	};
	// The command's result holds the playlist entry ID mpv gives the file
	mpv_node result = {};
	int error = mpv_command_ret(_mpvHandle, loadCommand, &result);
	int64_t entryID = -1;
	if (error >= 0 && result.format == MPV_FORMAT_NODE_MAP) {
		for (int index = 0; index < result.u.list->num; index++) {
			mpv_node *value = result.u.list->values + index;
			if (zen_mpv_compare_strings(kMPVResultKey_playlist_entry_id, result.u.list->keys[index]) &&
				value->format == MPV_FORMAT_INT64) {
				entryID = value->u.int64;
			}
		}
	}
	mpv_free_node_contents(&result);
	if (entryID < 0 && failure) {
		*failure = zen_mpv_to_nsstring(mpv_error_string(error < 0 ? error : MPV_ERROR_GENERIC));
	}

	[self pausePlayback];
	return entryID;
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

- (ZENMPVCommandResult)mpvSeek:(double)target flags:(const char *const)flags {
	// The command holds a pointer to this stack buffer, which stays valid
	// until mpv_command returns
	char targetArgument[32];
	zen_mpv_format_double(target, targetArgument, sizeof(targetArgument));
	const char *command[] = {
		kMPVCommand_seek,
		targetArgument,
		flags,
		nil
	};
	int error = [self mpvCommand:command];
	if (error >= 0) {
		return ZENMPVCommandResultAccepted;
	}
	NSLog(@"mpv seek %s %s failed: %s", targetArgument, flags, mpv_error_string(error));
	// mpv reports a seek before the file has loaded as a generic command error,
	// and a bad target such as NaN as an invalid parameter
	return (error == MPV_ERROR_COMMAND) ? ZENMPVCommandResultNotReady : ZENMPVCommandResultRejected;
}

- (ZENMPVCommandResult)seekBySeconds:(double)seconds {
	return [self mpvSeek:seconds flags:kMPVCommandParam_relative];
}

- (ZENMPVCommandResult)seekToSeconds:(double)seconds {
	return [self mpvSeek:seconds flags:kMPVCommandParam_absolute];
}

- (ZENMPVCommandResult)seekToPercentage:(double)percentage {
	return [self mpvSeek:percentage flags:kMPVCommandParam_absolute_percent];
}

- (void)mpvHandleEvents {
	// mpv calls zen_mpv_wakeup whenever it has events, which can queue more of
	// these calls behind the one that handles MPV_EVENT_SHUTDOWN and destroys the
	// handle. Those find nothing left to handle. They run on the same serial queue
	// as the destruction, so this check can't race with it.
	if (!_mpvHandle) {
		return;
	}
	while (true) {
		mpv_event *event = mpv_wait_event(_mpvHandle, 0);
		mpv_event_id eid = event->event_id;

		if (eid == MPV_EVENT_NONE) {
			// MPV_EVENT_NONE means the event queue is empty, meaning we
			// can break out of the outer loop and let this thread return
			break;
		} else if (eid == MPV_EVENT_SHUTDOWN) {
			[self destroyHandle];
			break;
		}
		switch (eid) {
			case MPV_EVENT_LOG_MESSAGE: {
				mpv_event_log_message *msg = event->data;
				NSLog(@"MPV_EVENT_LOG_MESSAGE: [%s] <%s> %s", msg->prefix, msg->level, msg->text);
				break;
			}
			case MPV_EVENT_START_FILE: {
				int64_t entryID = ((mpv_event_start_file *)event->data)->playlist_entry_id;
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.player playerControllerDidStartFile:entryID];
				});
				break;
			}
			case MPV_EVENT_END_FILE: {
				// Copy out what's needed: the event is only valid until the next one
				mpv_event_end_file *end = event->data;
				int64_t entryID = end->playlist_entry_id;
				ZENMPVEndReason reason = ZENMPVEndReasonStopped;
				NSString *failure = nil;
				if (end->reason == MPV_END_FILE_REASON_EOF) {
					reason = ZENMPVEndReasonFinished;
				} else if (end->reason == MPV_END_FILE_REASON_ERROR) {
					reason = ZENMPVEndReasonFailed;
					failure = zen_mpv_to_nsstring(mpv_error_string(end->error));
				}
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.player playerControllerDidEndFile:entryID reason:reason failure:failure];
				});
				break;
			}
			case MPV_EVENT_FILE_LOADED: {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.player playerControllerDidLoadFile];
				});
				break;
			}
			case MPV_EVENT_SEEK: {
				dispatch_async(dispatch_get_main_queue(), ^{
					self.player.seeking = YES;
				});
				break;
			}
			case MPV_EVENT_PLAYBACK_RESTART: {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self.player playerControllerDidRestartPlayback];
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

					const char *propertyName = nil;
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
							double percentPos = ZENDoubleFromNode(valueNode);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.positionPercent = percentPos;
							});
						} else if (zen_mpv_compare_strings(kMPVProperty_time_pos, propertyName)) {
							double seconds = ZENDoubleFromNode(valueNode);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.positionSeconds = seconds;
							});
						} else if (zen_mpv_compare_strings(kMPVProperty_duration, propertyName)) {
							double seconds = ZENDoubleFromNode(valueNode);
							dispatch_async(dispatch_get_main_queue(), ^{
								self.player.durationSeconds = seconds;
							});
						} else if (zen_mpv_compare_strings(kMPVProperty_path, propertyName)) {
							// mpv reports the path exactly as -openFileURL: passed it, a file
							// system representation, so convert it back the same way
							if (valueNode->format == MPV_FORMAT_STRING && valueNode->u.string) {
								NSURL *url = [NSURL fileURLWithFileSystemRepresentation:valueNode->u.string isDirectory:NO relativeToURL:nil];
								// NSLog(@"Path: %@", url);
								dispatch_async(dispatch_get_main_queue(), ^{
									self.player.fileURL = url;
								});
							}
						}
					}

					mpv_free_node_contents(&node);
				}

				break;
			}
			case MPV_EVENT_QUEUE_OVERFLOW: {
				NSLog(@"WARNING: mpv's event queue overflowed, so some of its events were lost");
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
	ZENMPVPlayerController *controller = (__bridge ZENMPVPlayerController *)ctx;
	dispatch_async(controller->_eventQueue, ^{
		[controller mpvHandleEvents];
	});
}
