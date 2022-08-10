//
//  MPVFunctions.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVFunctions.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

NSString *zen_mpv_string(const char *str) {
	return [NSString stringWithCString:str encoding:NSASCIIStringEncoding];
}

void zen_mpv_set_bool_property(mpv_handle* mpv, const char* const property, BOOL value) {
	mpv_node node = {
		.u.flag = (int)value,
		.format = MPV_FORMAT_FLAG
	};
	mpv_set_property(mpv, property, MPV_FORMAT_NODE, &node);
}
