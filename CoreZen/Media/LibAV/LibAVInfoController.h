//
//  LibAVInfoController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENLibAVRenderController;
struct AVFormatContext;
struct AVCodec;
struct AVStream;

@interface ZENLibAVInfoController : NSObject <ZENIdentifiable>

- (instancetype)initWithMediaPath:(NSString *)mediaPath;

- (struct AVFormatContext *)formatContextHandle;
- (const struct AVCodec *)videoCodecHandle;
- (const struct AVStream *)videoStreamHandle;

- (void)terminate;

- (ZENLibAVRenderController *)frameRenderController;

- (NSUInteger)durationMicroseconds;
- (double)durationSeconds;

// The size of the frames as stored, before rotation
- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

// See ZENMediaFile
- (NSUInteger)rotationDegrees;
- (double)pixelAspectRatio;

// Codec names, or nil if the file has no stream of that kind that can be decoded, or
// couldn't be read. See ZENMediaFile.
- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
