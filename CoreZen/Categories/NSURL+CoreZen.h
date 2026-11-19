//
//  NSURL+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CoreZen)

// outVolumeName and outVolumeURL are required; outVolumeUUID and outError may be NULL
- (BOOL)zen_volumeName:(NSString *_Nullable *_Nonnull)outVolumeName
			 volumeURL:(NSURL *_Nullable *_Nonnull)outVolumeURL
			volumeUUID:(NSUUID *_Nullable *_Nullable)outVolumeUUID
				 error:(NSError *_Nullable *_Nullable)outError;

+ (BOOL)zen_volumeInfoForUUID:(NSUUID *)volumeUUID
				   volumeName:(NSString *_Nullable *_Nonnull)outVolumeName
					volumeURL:(NSURL *_Nullable *_Nonnull)outVolumeURL;

// Path of url relative to this URL, or nil if url is neither this URL nor
// inside it. The result keeps the separator after this URL's path, e.g.
// /Volumes/Media to /Volumes/Media/Movies/a.mp4 gives @"/Movies/a.mp4". From
// the root URL "/" it has no leading separator, and for the same path it's @"".
- (nullable NSString *)zen_relativePathToURL:(NSURL *)url;

// Inverse of zen_relativePathToURL:. Appends relativePath to this URL's path as
// a file system path, so a leading separator and characters like " ", "#" and
// "%" are taken literally, not as URL syntax. /Volumes/Media with
// @"/Movies/a.mp4" gives /Volumes/Media/Movies/a.mp4. Returns nil if this URL
// has no path or relativePath is nil.
- (nullable NSURL *)zen_URLByAppendingRelativePath:(nullable NSString *)relativePath
									   isDirectory:(BOOL)isDirectory;

- (NSUInteger)zen_fileSize;

@end

NS_ASSUME_NONNULL_END
