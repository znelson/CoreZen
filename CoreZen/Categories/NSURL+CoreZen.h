//
//  NSURL+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import <Foundation/Foundation.h>

@interface NSURL (CoreZen)

- (BOOL)zen_volumeName:(NSString **)outVolumeName
			 volumeURL:(NSURL **)outVolumeURL
			volumeUUID:(NSUUID **)outVolumeUUID
				 error:(NSError **)outError;

+ (BOOL)zen_volumeInfoForUUID:(NSUUID *)volumeUUID
				   volumeName:(NSString **)outVolumeName
					volumeURL:(NSURL **)outVolumeURL;

// Path of url relative to this URL, or nil if url is neither this URL nor
// inside it. The result keeps the separator after this URL's path, e.g.
// /Volumes/Media to /Volumes/Media/Movies/a.mp4 gives @"/Movies/a.mp4". From
// the root URL "/" it has no leading separator, and for the same path it's @"".
- (NSString *)zen_relativePathToURL:(NSURL *)url;

- (NSUInteger)zen_fileSize;

@end
