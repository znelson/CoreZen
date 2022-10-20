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

BOOL zen_mpv_compare_strings(const char* const one, const char* const two);

void zen_mpv_init_pthread_mutex_cond(pthread_mutex_t* mutex, pthread_cond_t* cond);
void zen_mpv_destroy_pthread_mutex_cond(pthread_mutex_t* mutex, pthread_cond_t* cond);

