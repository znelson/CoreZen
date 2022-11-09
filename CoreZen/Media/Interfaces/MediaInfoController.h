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

// (const AVCodec *)videoCodecHandle;
- (const void *)videoCodecHandle;

// (const AVCodec *)audioCodecHandle;
- (const void *)audioCodecHandle;

// (const AVCodecParameters *)videoCodecParamsHandle;
- (const void *)videoCodecParamsHandle;

// (const AVCodecParameters *)audioCodecParamsHandle;
- (const void *)audioCodecParamsHandle;

- (void)terminate;

- (NSUInteger)durationMicroseconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
