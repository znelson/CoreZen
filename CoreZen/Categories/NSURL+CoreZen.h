//
//  NSURL+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 3/16/22.
//

#import <Foundation/Foundation.h>

@interface NSURL (AlchemistCore)

- (BOOL)czn_volumeName:(NSString **)outVolumeName
			 volumeURL:(NSURL **)outVolumeURL
			volumeUUID:(NSUUID **)outVolumeUUID
				 error:(NSError **)outError;

+ (BOOL)czn_volumeInfoForUUID:(NSUUID *)volumeUUID
				   volumeName:(NSString **)outVolumeName
					volumeURL:(NSURL **)outVolumeURL;

- (NSString *)czn_relativePathToURL:(NSURL *)url;

- (NSUInteger)czn_fileSize;

@end
