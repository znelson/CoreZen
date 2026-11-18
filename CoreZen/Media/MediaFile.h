//
//  MediaFile.h
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@interface ZENMediaFile : NSObject <ZENIdentifiable>

@property (nonatomic, strong, readonly) NSURL *fileURL;

+ (instancetype)mediaFileWithURL:(NSURL *)url;

// Terminate frame renderer (and frame render controller) if one was created,
// then terminate media file format context
- (void)terminateMediaFile;

// Call before application terminates to terminate all ZENMediaFile instances
+ (void)terminateAllMediaFiles;

- (NSUInteger)durationMicroseconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

// Short names of the codecs of the file's video and audio, like "h264" and "aac". nil if
// the file has no stream of that kind that can be decoded, like the audio of a video with
// no sound, or if the file couldn't be read.
- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

// Descriptive names of the same codecs, like "AAC (Advanced Audio Coding)". nil in the
// same cases.
- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
