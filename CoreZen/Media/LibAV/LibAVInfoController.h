//
//  LibAVInfoController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@class ZENLibAVRenderController;
@class ZENMediaFile;
struct AVFormatContext;
struct AVCodec;
struct AVStream;

@interface ZENLibAVInfoController : NSObject <ZENIdentifiable>

@property (nonatomic, weak, readonly) ZENMediaFile *mediaFile;

- (instancetype)initWithMediaFile:(ZENMediaFile *)mediaFile;

- (struct AVFormatContext *)formatContextHandle;
- (const struct AVCodec *)videoCodecHandle;
- (const struct AVStream *)videoStreamHandle;

- (void)terminate;

- (ZENLibAVRenderController *)frameRenderController;

- (NSUInteger)durationMicroseconds;
- (double)durationSeconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
