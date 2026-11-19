//
//  ObjectCache.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

#import <CoreZen/Identifier.h>
@protocol ZENIdentifiable;

NS_ASSUME_NONNULL_BEGIN

@interface ZENObjectCache : NSObject

+ (instancetype)weakObjectCache;
+ (instancetype)strongObjectCache;

// nil if nothing with this identifier is cached
- (nullable id)cachedObject:(ZENIdentifier)identifier;
- (void)cacheObject:(id<ZENIdentifiable>)object;
- (void)removeObject:(ZENIdentifier)identifier;

- (NSArray<id<ZENIdentifiable>> *)allCachedObjects;
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
