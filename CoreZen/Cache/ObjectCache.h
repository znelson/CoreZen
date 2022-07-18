//
//  ObjectCache.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

#import <CoreZen/Identifier.h>
@protocol ZENIdentifiable;

@interface ZENObjectCache : NSObject

+ (instancetype)weakObjectCache;
+ (instancetype)strongObjectCache;

- (id)cachedObject:(ZENIdentifier)identifier;
- (void)cacheObject:(id<ZENIdentifiable>)object;
- (void)removeObject:(ZENIdentifier)identifier;

@end
