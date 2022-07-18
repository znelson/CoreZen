//
//  NSURL+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import "NSURL+CoreZen.h"

@implementation NSURL (AlchemistCore)

- (BOOL)zen_volumeName:(NSString **)outVolumeName
			 volumeURL:(NSURL **)outVolumeURL
			volumeUUID:(NSUUID **)outVolumeUUID
				 error:(NSError **)outError {
	NSString *volumeUUID;
	if ([self getResourceValue:outVolumeName forKey:NSURLVolumeLocalizedNameKey error:outError] &&
		[self getResourceValue:outVolumeURL forKey:NSURLVolumeURLKey error:outError] &&
		[self getResourceValue:&volumeUUID forKey:NSURLVolumeUUIDStringKey error:outError]) {
		*outVolumeUUID = [[NSUUID alloc] initWithUUIDString:volumeUUID];
		return YES;
	}
	return NO;
}

+ (BOOL)zen_volumeInfoForUUID:(NSUUID *)volumeUUID
				   volumeName:(NSString **)outVolumeName
					volumeURL:(NSURL **)outVolumeURL {
	NSArray<NSURLResourceKey> *resourceKeys =
	@[
		NSURLVolumeLocalizedNameKey,
		NSURLVolumeURLKey,
		NSURLVolumeUUIDStringKey
	];

	NSArray *volumeURLs = [NSFileManager.defaultManager
						   mountedVolumeURLsIncludingResourceValuesForKeys:resourceKeys
						   options:NSVolumeEnumerationSkipHiddenVolumes];
	
	NSString *volumeUUIDString = [volumeUUID UUIDString];
	
	for (NSURL *volumeURL in volumeURLs) {
		NSString *uuid;
		NSError *error;
		if ([volumeURL getResourceValue:&uuid forKey:NSURLVolumeUUIDStringKey error:&error] &&
			[uuid isEqual:volumeUUIDString]) {
			
			[volumeURL getResourceValue:outVolumeName forKey:NSURLVolumeLocalizedNameKey error:&error];
			[volumeURL getResourceValue:outVolumeURL forKey:NSURLVolumeURLKey error:&error];
			return YES;
		}
	}
	return NO;
}

- (NSString *)zen_relativePathToURL:(NSURL *)url {
	
	NSString *fullPath = [url absoluteString];
	NSString *basePath = [self absoluteString];
	if ([fullPath hasPrefix:basePath]) {
		NSString *relativePath = [fullPath substringFromIndex:basePath.length];
		return relativePath;
	}
	return nil;
}

- (NSUInteger)zen_fileSize {
	NSError *error;
	NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.absoluteString error:&error];
	if (attributes) {
		return attributes.fileSize;
	}
	return 0;
}

@end
