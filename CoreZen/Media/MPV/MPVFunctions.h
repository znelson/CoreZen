//
//  MPVFunctions.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>

NSString *zen_mpv_string(const char *str);

typedef struct mpv_handle mpv_handle;

void zen_mpv_set_bool_property(mpv_handle* mpv, const char* const property, BOOL value);
