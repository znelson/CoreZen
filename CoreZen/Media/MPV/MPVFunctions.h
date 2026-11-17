//
//  MPVFunctions.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>

// Decodes a UTF-8 string from mpv. Returns nil for NULL.
NSString *zen_mpv_to_nsstring(const char *str);

// Formats a number as an mpv command argument. mpv reads command arguments as
// C strings, so the caller owns the buffer and keeps it alive for the command.
void zen_mpv_format_double(double value, char *buffer, size_t size);

typedef struct mpv_handle mpv_handle;

void zen_mpv_set_bool_property(mpv_handle *mpv, const char *const property, BOOL value);
void zen_mpv_set_string_property(mpv_handle *mpv, const char *const property, const char *const value);

BOOL zen_mpv_compare_strings(const char *const one, const char *const two);

void zen_mpv_init_pthread_mutex_cond(pthread_mutex_t *mutex, pthread_cond_t *cond);
void zen_mpv_destroy_pthread_mutex_cond(pthread_mutex_t *mutex, pthread_cond_t *cond);

void *zen_mpv_get_opengl_proc_address(void *ctx, const char *name);
