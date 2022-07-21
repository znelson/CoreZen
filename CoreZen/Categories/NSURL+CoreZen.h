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

- (NSString *)zen_relativePathToURL:(NSURL *)url;

- (NSUInteger)zen_fileSize;

@end
