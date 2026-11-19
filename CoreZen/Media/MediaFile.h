//
//  MediaFile.h
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZENMediaFile : NSObject <ZENIdentifiable>

@property (nonatomic, strong, readonly) NSURL *fileURL;

+ (instancetype)mediaFileWithURL:(NSURL *)url;

// Terminate frame renderer (and frame render controller) if one was created,
// then terminate media file format context
- (void)terminateMediaFile;

// Call before application terminates to terminate all ZENMediaFile instances
+ (void)terminateAllMediaFiles;

- (NSUInteger)durationMicroseconds;

// The video's size as it's shown, with its rotation applied, so a phone's portrait
// video is taller than it is wide. 0 if there's no video.
- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

// How far the video's frames are turned clockwise to show them upright: 0, 90, 180
// or 270 degrees. Phones store portrait video as landscape frames tagged with 90.
// ZENFrameRenderer's images are already turned.
- (NSUInteger)rotationDegrees;

// Short names of the codecs of the file's video and audio, like "h264" and "aac". nil if
// the file has no stream of that kind that can be decoded, like the audio of a video with
// no sound, or if the file couldn't be read.
- (nullable NSString *)videoCodecName;
- (nullable NSString *)audioCodecName;

// Descriptive names of the same codecs, like "AAC (Advanced Audio Coding)". nil in the
// same cases.
- (nullable NSString *)videoCodecLongName;
- (nullable NSString *)audioCodecLongName;

@end

NS_ASSUME_NONNULL_END
