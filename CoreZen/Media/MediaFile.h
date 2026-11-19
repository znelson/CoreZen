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

// The video's size as it's shown: the stored frame stretched to its pixel aspect
// ratio, then turned by its rotation. So a phone's portrait video is taller than
// it is wide, and a DVD's anamorphic 720x480 widescreen frames are 853x480. 0 if
// there's no video.
- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

// How far the video's frames are turned clockwise to show them upright: 0, 90, 180
// or 270 degrees. Phones store portrait video as landscape frames tagged with 90.
// ZENFrameRenderer's images are already turned.
- (NSUInteger)rotationDegrees;

// How wide each stored pixel is shown, relative to its height: 1 for square
// pixels, as most video has, and more than 1 for frames stored narrower than
// they're shown, like a DVD's anamorphic widescreen (32:27, about 1.185).
- (double)pixelAspectRatio;

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
