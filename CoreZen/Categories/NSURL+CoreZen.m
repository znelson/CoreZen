//
//  NSURL+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import "NSURL+CoreZen.h"

@implementation NSURL (CoreZen)

- (BOOL)zen_volumeName:(NSString **)outVolumeName
			 volumeURL:(NSURL **)outVolumeURL
			volumeUUID:(NSUUID **)outVolumeUUID
				 error:(NSError **)outError {
	NSString *volumeUUID;
	if ([self getResourceValue:outVolumeName forKey:NSURLVolumeLocalizedNameKey error:outError] &&
		[self getResourceValue:outVolumeURL forKey:NSURLVolumeURLKey error:outError] &&
		[self getResourceValue:&volumeUUID forKey:NSURLVolumeUUIDStringKey error:outError]) {
		if (outVolumeUUID) {
			*outVolumeUUID = [[NSUUID alloc] initWithUUIDString:volumeUUID];
		}
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
			if ([volumeURL getResourceValue:outVolumeName forKey:NSURLVolumeLocalizedNameKey error:&error] &&
				[volumeURL getResourceValue:outVolumeURL forKey:NSURLVolumeURLKey error:&error]) {
				return YES;
			}
			return NO;
		}
	}
	return NO;
}

- (NSString *)zen_relativePathToURL:(NSURL *)url {
	NSString *fullPath = [url path];
	NSString *basePath = [self path];
	if (![fullPath hasPrefix:basePath]) {
		return nil;
	}
	NSString *relativePath = [fullPath substringFromIndex:basePath.length];
	// The match must end at a path separator, so /Volumes/Media doesn't contain
	// /Volumes/Media2. The root path "/" already ends with one.
	if (relativePath.length > 0 && ![relativePath hasPrefix:@"/"] && ![basePath hasSuffix:@"/"]) {
		return nil;
	}
	return relativePath;
}

- (NSURL *)zen_URLByAppendingRelativePath:(NSString *)relativePath
							  isDirectory:(BOOL)isDirectory {
	NSString *basePath = [self path];
	if (!basePath || !relativePath) {
		return nil;
	}
	// Join as paths, not URL strings: resolving @"/Movies" as a relative URL
	// would replace this URL's path, and "#" or "?" would be parsed as URL syntax
	NSString *path = [basePath stringByAppendingPathComponent:relativePath];
	return [NSURL fileURLWithPath:path isDirectory:isDirectory];
}

- (NSUInteger)zen_fileSize {
	NSError *error;
	NSDictionary *attributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.path error:&error];
	if (attributes) {
		return attributes.fileSize;
	}
	return 0;
}

@end
