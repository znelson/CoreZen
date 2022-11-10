//
//  MediaInfoController.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <Foundation/Foundation.h>

@protocol ZENFrameRenderController;

@protocol ZENMediaInfoController <NSObject>

- (NSObject<ZENFrameRenderController> *)frameRenderController;

// (AVFormatContext *)formatContextHandle;
- (void *)formatContextHandle;

// (const AVCodec *)videoCodecHandle;
- (const void *)videoCodecHandle;

// (const AVStream *)videoStreamHandle;
- (const void *)videoStreamHandle;

- (void)terminate;

- (NSUInteger)durationMicroseconds;
- (double)durationSeconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
