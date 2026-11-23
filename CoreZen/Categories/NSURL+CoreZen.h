//
//  NSURL+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CoreZen)

/// Gets the name, URL and UUID of the volume this URL is on.
///
/// The name and URL pointers are required; the UUID and error pointers may be
/// NULL. It returns NO, with the error set, if the volume's details can't be
/// read. The UUID can be nil even when it returns YES, because some volumes,
/// like many network shares, have none.
- (BOOL)zen_volumeName:(NSString *_Nullable *_Nonnull)outVolumeName
			 volumeURL:(NSURL *_Nullable *_Nonnull)outVolumeURL
			volumeUUID:(NSUUID *_Nullable *_Nullable)outVolumeUUID
				 error:(NSError *_Nullable *_Nullable)outError;

/// Finds the mounted volume with a UUID, and gets its name and URL.
///
/// It returns NO if no mounted volume that isn't hidden has that UUID, or if
/// its details can't be read.
+ (BOOL)zen_volumeInfoForUUID:(NSUUID *)volumeUUID
				   volumeName:(NSString *_Nullable *_Nonnull)outVolumeName
					volumeURL:(NSURL *_Nullable *_Nonnull)outVolumeURL;

/// The path of a URL relative to this one, or nil if the URL is neither this
/// one nor inside it.
///
/// The result keeps the separator after this URL's path: /Volumes/Media to
/// /Volumes/Media/Movies/a.mp4 gives @"/Movies/a.mp4". From the root URL "/" it
/// has no leading separator, and for the same path it's @"". A path only counts
/// as inside this one at a separator, so /Volumes/Media2 isn't inside
/// /Volumes/Media.
- (nullable NSString *)zen_relativePathToURL:(NSURL *)url;

/// Appends a relative path to this URL's path, undoing
/// `zen_relativePathToURL:`.
///
/// The relative path is a file system path, so a leading separator and
/// characters like " ", "#" and "%" are taken literally, not as URL syntax.
/// /Volumes/Media with @"/Movies/a.mp4" gives /Volumes/Media/Movies/a.mp4. It
/// returns nil if this URL has no path, or the relative path is nil.
- (nullable NSURL *)zen_URLByAppendingRelativePath:(nullable NSString *)relativePath
									   isDirectory:(BOOL)isDirectory;

/// The size in bytes of the file at this URL, or 0 if it can't be read.
- (NSUInteger)zen_fileSize;

@end

NS_ASSUME_NONNULL_END
