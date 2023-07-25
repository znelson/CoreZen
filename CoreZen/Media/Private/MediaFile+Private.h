//
//  MediaFile+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <CoreZen/MediaFile.h>

@class ZENLibAVInfoController;

@interface ZENMediaFile ()

@property (nonatomic, strong, readonly) ZENLibAVInfoController *mediaInfoController;

@end
