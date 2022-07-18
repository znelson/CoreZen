//
//  ObjectCache.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

#import <CoreZen/Identifier.h>
@protocol CZNIdentifiable;

@interface CZNObjectCache : NSObject

+ (instancetype)weakObjectCache;
+ (instancetype)strongObjectCache;

- (id)cachedObject:(CZNIdentifier)identifier;
- (void)cacheObject:(id<CZNIdentifiable>)object;
- (void)removeObject:(CZNIdentifier)identifier;

@end
