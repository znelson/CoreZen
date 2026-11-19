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

/// Objects by identifier, which any thread can use.
///
/// A repository keeps its objects in one, so that each identifier has one object
/// in memory.
@interface ZENObjectCache : NSObject

/// Makes a cache that holds each object only while something else holds it too.
+ (instancetype)weakObjectCache;

/// Makes a cache that holds each object until it's removed.
+ (instancetype)strongObjectCache;

/// The object cached with this identifier, or nil if there's none.
- (nullable id)cachedObject:(ZENIdentifier)identifier;

/// Caches an object by its identifier, unless the cache has an object with that
/// identifier already.
///
/// The cache keeps the first object it gets for an identifier, so ignoring a
/// second one keeps the one that the rest of the app may already be using.
- (void)cacheObject:(id<ZENIdentifiable>)object;

/// Removes the object with this identifier, if there's one.
- (void)removeObject:(ZENIdentifier)identifier;

/// Every object in the cache, in no particular order.
- (NSArray<id<ZENIdentifiable>> *)allCachedObjects;

/// Removes every object.
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END
