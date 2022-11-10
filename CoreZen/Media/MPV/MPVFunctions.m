//
//  MPVFunctions.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVFunctions.h"

@import Darwin.POSIX.pthread;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

NSString *zen_mpv_to_nsstring(const char *str) {
	return [NSString stringWithCString:str encoding:NSASCIIStringEncoding];
}

const char *zen_nsstring_to_mpv(NSString *str) {
	return [str cStringUsingEncoding:NSASCIIStringEncoding];
}

const char *zen_double_to_mpv_string(double d) {
	NSString *str = [NSString stringWithFormat:@"%f", d];
	return zen_nsstring_to_mpv(str);
}

void zen_mpv_set_bool_property(mpv_handle* mpv, const char* const property, BOOL value) {
	mpv_node node = {
		.u.flag = (int)value,
		.format = MPV_FORMAT_FLAG
	};
	mpv_set_property(mpv, property, MPV_FORMAT_NODE, &node);
}

BOOL zen_mpv_compare_strings(const char* const one, const char* const two) {
	return strcmp(one, two) == 0;
}

void zen_mpv_init_pthread_mutex_cond(pthread_mutex_t* mutex, pthread_cond_t* cond) {
	pthread_mutexattr_t mutexAttrs;
	pthread_mutexattr_init(&mutexAttrs);
	pthread_mutexattr_setpolicy_np(&mutexAttrs, _PTHREAD_MUTEX_POLICY_FIRSTFIT);
	pthread_mutex_init(mutex, &mutexAttrs);
	pthread_mutexattr_destroy(&mutexAttrs);
	
	pthread_condattr_t condAttrs;
	pthread_condattr_init(&condAttrs);
	pthread_cond_init(cond, &condAttrs);
	pthread_condattr_destroy(&condAttrs);
}

void zen_mpv_destroy_pthread_mutex_cond(pthread_mutex_t* mutex, pthread_cond_t* cond) {
	pthread_mutex_destroy(mutex);
	pthread_cond_destroy(cond);
}
