//
//  ObjectCache.m
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import "ObjectCache.h"
#import "Identifiable.h"

#import <stdatomic.h>

@interface ZENObjectCache ()

@property (nonatomic, strong, readonly) NSMapTable *mapTable;
@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

- (instancetype)initWeakObjectCache;
- (instancetype)initStrongObjectCache;

- (void)initCommon:(NSString *)queueLabel;

@end

@implementation ZENObjectCache

- (instancetype)init {
	return [self initWeakObjectCache];
}

- (void)initCommon:(NSString *)queueLabel {
	static atomic_uint_fast64_t nextIdentifier = 0;
	uint64_t cacheID = atomic_fetch_add(&nextIdentifier, 1);
	
	NSString *label = [NSString stringWithFormat:@"%@-%llu", queueLabel, cacheID];
	_isolationQueue = dispatch_queue_create(label.UTF8String, DISPATCH_QUEUE_CONCURRENT);
}

- (instancetype)initWeakObjectCache {
	self = [super init];
	if (self) {
		_mapTable = [NSMapTable strongToWeakObjectsMapTable];
		
		[self initCommon:@"ZENWeakObjectCache"];
	}
	return self;
}

+ (instancetype)weakObjectCache {
	return [[ZENObjectCache alloc] initWeakObjectCache];
}

- (instancetype)initStrongObjectCache {
	self = [super init];
	if (self) {
		_mapTable = [NSMapTable strongToStrongObjectsMapTable];
		
		[self initCommon:@"ZENStrongObjectCache"];
	}
	return self;
}

+ (instancetype)strongObjectCache {
	return [[ZENObjectCache alloc] initStrongObjectCache];
}

- (id)cachedObject:(ZENIdentifier)identifier {
	__block id object = nil;
	dispatch_sync(self.isolationQueue, ^{
		object = [self.mapTable objectForKey:@(identifier)];
		if (object == [NSNull null]) {
			object = nil;
		}
	});
	return object;
}

- (void)cacheObject:(id<ZENIdentifiable>)object {
	dispatch_barrier_async(self.isolationQueue, ^{
		NSNumber *identifier = @(object.identifier);
		id existing = [self.mapTable objectForKey:identifier];
		// There must be either no entry, or the entry expired because nothing was holding a strong ref
		if (!existing || existing == NSNull.null) {
			[self.mapTable setObject:object forKey:identifier];
		}
	});
}

- (void)removeObject:(ZENIdentifier)identifier {
	dispatch_barrier_async(self.isolationQueue, ^{
		[self.mapTable removeObjectForKey:@(identifier)];
	});
}

- (NSArray<id<ZENIdentifiable>> *)allCachedObjects {
	__block NSMutableArray<id<ZENIdentifiable>> *objs = [NSMutableArray new];
	dispatch_sync(self.isolationQueue, ^{
		NSEnumerator<id<ZENIdentifiable>> *enumerator = self.mapTable.objectEnumerator;
		for (id obj in enumerator) {
			if (obj && obj != NSNull.null) {
				[objs addObject:obj];
			}
		}
	});
	return objs;
}

- (void)removeAllObjects {
	dispatch_barrier_async(self.isolationQueue, ^{
		[self.mapTable removeAllObjects];
	});
}

@end
