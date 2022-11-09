//
//  LibAVInfoController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/MediaInfoController.h>

@class ZENMediaFile;

@interface ZENLibAVInfoController : NSObject <ZENMediaInfoController>

@property (nonatomic, weak, readonly) ZENMediaFile *mediaFile;

- (instancetype)initWithMediaFile:(ZENMediaFile *)mediaFile;

// ZENMediaInfoController protocol

// (const AVCodec *)videoCodecHandle;
- (const void *)videoCodecHandle;

// (const AVStream *)videoStreamHandle;
- (const void *)videoStreamHandle;

- (void)terminate;

- (NSObject<ZENFrameRenderController> *)frameRenderController;

- (NSUInteger)durationMicroseconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
