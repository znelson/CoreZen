//
//  ObjectCache.m
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import "ObjectCache.h"
#import "Identifiable.h"

@interface CZNObjectCache ()

@property (nonatomic, strong, readonly) NSMapTable *mapTable;
@property (nonatomic, strong, readonly) dispatch_queue_t isolationQueue;

- (instancetype)initWeakObjectCache;
- (instancetype)initStrongObjectCache;

@end

@implementation CZNObjectCache

- (instancetype)init {
	return [self initWeakObjectCache];
}

- (instancetype)initWeakObjectCache {
	self = [super init];
	if (self) {
		_mapTable = [NSMapTable strongToWeakObjectsMapTable];
		_isolationQueue = dispatch_queue_create(@"CZNWeakObjectCache".UTF8String, DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

+ (instancetype)weakObjectCache {
	return [[CZNObjectCache alloc] initWeakObjectCache];
}

- (instancetype)initStrongObjectCache {
	self = [super init];
	if (self) {
		_mapTable = [NSMapTable strongToStrongObjectsMapTable];
		_isolationQueue = dispatch_queue_create(@"CZNStrongObjectCache".UTF8String, DISPATCH_QUEUE_CONCURRENT);
	}
	return self;
}

+ (instancetype)strongObjectCache {
	return [[CZNObjectCache alloc] initStrongObjectCache];
}

- (id)cachedObject:(CZNIdentifier)identifier {
	__block id object = nil;
	dispatch_sync(self.isolationQueue, ^{
		object = [self.mapTable objectForKey:@(identifier)];
		if (object == [NSNull null]) {
			object = nil;
		}
	});
	return object;
}

- (void)cacheObject:(id<CZNIdentifiable>)object {
	dispatch_barrier_async(self.isolationQueue, ^{
		NSNumber *identifier = @(object.identifier);
		id existing = [self.mapTable objectForKey:identifier];
		// There must be either no entry, or the entry expired because nothing was holding a strong ref
		if (!existing || existing == [NSNull null]) {
			[self.mapTable setObject:object forKey:identifier];
		}
	});
}

- (void)removeObject:(CZNIdentifier)identifier {
	dispatch_barrier_async(self.isolationQueue, ^{
		[self.mapTable removeObjectForKey:@(identifier)];
	});
}

@end
