//
//  MPVFunctions.m
//  CoreZen
//
//  Created by Zach Nelson on 7/25/22.
//

#import "MPVFunctions.h"
#import "MPVViewLayer.h"

void *zen_mpv_get_proc_address_context = &zen_mpv_get_proc_address_context;

NSString *zen_mpv_string(const char *str) {
	return [NSString stringWithCString:str encoding:NSASCIIStringEncoding];
}

void *zen_mpv_get_proc_address(void *ctx, const char *name) {
	CFStringRef bundleName = CFStringCreateWithCString(kCFAllocatorDefault, "com.apple.opengl", kCFStringEncodingASCII);
	CFBundleRef bundle = CFBundleGetBundleWithIdentifier(bundleName);
	CFStringRef functionName = CFStringCreateWithCString(kCFAllocatorDefault, name, kCFStringEncodingASCII);
	void *function = CFBundleGetFunctionPointerForName(bundle, functionName);
	return function;
}
