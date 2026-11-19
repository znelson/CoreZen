//
//  MediaFile.h
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

NS_ASSUME_NONNULL_BEGIN

/// A media file's details, read with FFmpeg: its duration, frame size,
/// rotation and codecs.
///
/// Making one opens the file and reads its details, which reads from disk, so a
/// file on a slow volume can keep the calling thread waiting. Call
/// ``terminateMediaFile`` once you're done with it, or
/// ``terminateAllMediaFiles`` before the app quits.
@interface ZENMediaFile : NSObject <ZENIdentifiable>

/// The file's URL.
@property (nonatomic, strong, readonly) NSURL *fileURL;

/// Opens a media file and reads its details.
///
/// A file that can't be opened still makes a media file, whose details are 0
/// or nil.
+ (instancetype)mediaFileWithURL:(NSURL *)url;

/// Closes the file, and stops its frame renderer's work, if it has one.
///
/// Renders still waiting complete with no image. A media file released without
/// this terminates itself, and logs that it wasn't terminated first.
- (void)terminateMediaFile;

/// Terminates every media file that hasn't been terminated.
///
/// Call it before the app quits.
+ (void)terminateAllMediaFiles;

/// The file's duration in microseconds, or 0 if it's unknown or the file
/// couldn't be read.
- (NSUInteger)durationMicroseconds;

/// The video's width as it's shown, or 0 if there's no video.
///
/// The size as it's shown is the stored frame stretched to its pixel aspect
/// ratio, then turned by its rotation. So a phone's portrait video is taller
/// than it is wide, and a DVD's anamorphic 720x480 widescreen frames are
/// 853x480.
- (NSUInteger)frameWidth;

/// The video's height as it's shown, or 0 if there's no video.
///
/// Like ``frameWidth``, it's the size after the pixel aspect ratio and the
/// rotation.
- (NSUInteger)frameHeight;

/// How far the video's frames are turned clockwise to show them upright: 0,
/// 90, 180 or 270 degrees.
///
/// Phones store portrait video as landscape frames tagged with 90.
/// ``ZENFrameRenderer``'s images are already turned.
- (NSUInteger)rotationDegrees;

/// How wide each stored pixel is shown, relative to its height.
///
/// It's 1 for square pixels, as most video has, and more than 1 for frames
/// stored narrower than they're shown, like a DVD's anamorphic widescreen
/// (32:27, about 1.185).
- (double)pixelAspectRatio;

/// The short name of the video's codec, like "h264".
///
/// It's nil if the file has no video stream that can be decoded, or if the file
/// couldn't be read.
- (nullable NSString *)videoCodecName;

/// The short name of the audio's codec, like "aac".
///
/// It's nil if the file has no audio stream that can be decoded, like a video
/// with no sound, or if the file couldn't be read.
- (nullable NSString *)audioCodecName;

/// The descriptive name of the video's codec, like "H.264 / AVC / MPEG-4 AVC /
/// MPEG-4 part 10".
///
/// It's nil in the same cases as ``videoCodecName``.
- (nullable NSString *)videoCodecLongName;

/// The descriptive name of the audio's codec, like "AAC (Advanced Audio
/// Coding)".
///
/// It's nil in the same cases as ``audioCodecName``.
- (nullable NSString *)audioCodecLongName;

@end

NS_ASSUME_NONNULL_END
