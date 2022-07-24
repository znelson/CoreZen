//
//  MPVController.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MPVController.h"
#import "MPVConstants.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import <mpv/client.h>

#pragma clang diagnostic pop

@interface MPVUtils : NSObject
@end

@implementation MPVUtils
@end

@interface MPVController ()
{
	mpv_handle *_mpvHandle;
}

@property (nonatomic, strong) NSString *clientName;
@property (nonatomic, strong) NSString *version;

@end

@implementation MPVController

- (instancetype)init {
	self = [super init];
	if (self) {
		_clientName = @"";
	}
	return self;
}

- (void)mpvInit {
	if (!_mpvHandle) {
		_mpvHandle = mpv_create();
		
		const char* clientName = mpv_client_name(_mpvHandle);
		self.clientName = [NSString stringWithCString:clientName encoding:NSASCIIStringEncoding];
		
		const char* version = mpv_get_property_string(_mpvHandle, kMPVProperty_MPVVersion);
		self.version = [NSString stringWithCString:version encoding:NSASCIIStringEncoding];
	}
}

- (void)mpvTerminate {
	
}

@end
