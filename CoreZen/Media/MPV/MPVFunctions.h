//
//  MPVFunctions.h
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import <Foundation/Foundation.h>

NSString *zen_mpv_string(const char *str);

extern void *zen_mpv_get_proc_address_context;
void *zen_mpv_get_proc_address(void *ctx, const char *name);
