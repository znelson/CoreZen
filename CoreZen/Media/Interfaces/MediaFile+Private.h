//
//  MediaFile+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import <CoreZen/MediaFile.h>

@protocol ZENMediaInfoController;

@interface ZENMediaFile ()

@property (nonatomic, strong, readonly) NSObject<ZENMediaInfoController> *mediaInfoController;

@end
