//
//  MediaFile.h
//  CoreZen
//
//  Created by Zach Nelson on 3/18/22.
//

#import <Foundation/Foundation.h>

@interface ZENMediaFile : NSObject

@property (nonatomic, strong, readonly) NSURL *fileURL;

+ (instancetype)mediaFileWithURL:(NSURL*)url;

- (NSUInteger)durationMicroseconds;

- (NSUInteger)frameWidth;
- (NSUInteger)frameHeight;

- (NSString *)videoCodecName;
- (NSString *)audioCodecName;

- (NSString *)videoCodecLongName;
- (NSString *)audioCodecLongName;

@end
