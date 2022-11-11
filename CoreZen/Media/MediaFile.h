//
//  MediaFile.h
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENFrameRenderer;

@interface ZENMediaFile : NSObject <ZENIdentifiable>

@property (nonatomic, strong, readonly) NSURL *fileURL;

+ (instancetype)mediaFileWithURL:(NSURL*)url;

// Terminate frame renderer (and frame render controller) if one was created,
// then terminate media file format context
- (void)terminateMediaFile;

// Call before application terminates to terminate all ZENMediaFile instances
+ (void)terminateAllMediaFiles;

- (ZENFrameRenderer *)frameRenderer;

- (NSUInteger)durationMicroseconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
