//
//  ObjectRepository.m
//  CoreZen
//
//  Created by Zach Nelson on 6/28/22.
//

#import "ObjectRepository.h"
#import "ObjectCache.h"
#import "DatabaseTable.h"
#import "DatabaseQueue.h"
#import "Database.h"
#import "ResultSet.h"
#import "DomainCommon.h"

#import <os/lock.h>

@interface ZENObjectRepository () {
	// Objects whose async init is still running, by identifier. A fetch that
	// finds one of them in the cache waits on its group before returning it.
	NSMutableDictionary<NSNumber *, dispatch_group_t> *_pendingInits;
	os_unfair_lock _pendingInitsLock;
}

@property (nonatomic, strong, readonly) NSObject<ZENDatabaseTable> *table;
@property (nonatomic, strong, readonly) ZENDatabaseQueue *queue;
@property (nonatomic, strong, readonly) Class<ZENDomainObject> embryo;
@property (nonatomic, strong, readonly) ZENObjectCache *cache;
@property (nonatomic, weak, readonly) id<ZENDataModel> dataModel;

// Runs synchronously. To be called on database queue.
- (id<ZENIdentifiable>)createObjectFromRow:(ZENResultSet *)row;

// Runs synchronously. To be called on database queue.
- (id<ZENIdentifiable>)fetchObjectByIdentifier:(ZENIdentifier)identifier
									  database:(ZENDatabase *)database;

// To be called on database queue, before the objects are cached.
- (void)startAsyncInit:(NSArray *)objects;

- (void)deliverObjects:(NSArray *)objects whenInitialized:(ZENFetchResultsBlock)resultsBlock;

@end

@implementation ZENObjectRepository

#pragma mark - Init

- (instancetype)initWithDataModel:(id<ZENDataModel>)dataModel
					   tableClass:(Class<ZENDatabaseTable>)tableClass
					databaseQueue:(ZENDatabaseQueue *)databaseQueue
			   domainObjectEmbryo:(Class<ZENDomainObject>)embryo
						cacheType:(ZENObjectRepositoryCacheType)cacheType {
	self = [super init];
	if (self) {
		_pendingInits = [NSMutableDictionary new];
		_pendingInitsLock = OS_UNFAIR_LOCK_INIT;
		_dataModel = dataModel;
		_table = [(Class)tableClass new];
		_queue = databaseQueue;
		_embryo = embryo;
		_cache = (cacheType == ZENObjectRepositoryCacheType_Strong) ? [ZENObjectCache strongObjectCache] : [ZENObjectCache weakObjectCache];
	}
	return self;
}

#pragma mark - [private] Create

- (id<ZENIdentifiable>)createObjectFromRow:(ZENResultSet *)row {
	ZENDataTransferObject *dto = [self.table dtoFromRow:row];
	id<ZENIdentifiable> object = [[(Class)self.embryo alloc] initWithDTO:dto];
	return object;
}

#pragma mark - [private] Fetch

- (id<ZENIdentifiable>)fetchObjectByIdentifier:(ZENIdentifier)identifier
									  database:(ZENDatabase *)database {
	ZENResultSet *rs = [self.table rowByIdentifier:identifier database:database];
	id<ZENIdentifiable> object = nil;
	if ([rs next]) {
		object = [self createObjectFromRow:rs];
	}
	[rs close];
	return object;
}

#pragma mark - [private] Async init

- (void)startAsyncInit:(NSArray *)objects {
	// Objects are registered here before they're cached, so a fetch that finds
	// one in the cache also finds its init in progress
	for (id<ZENDomainObject> object in objects) {
		NSNumber *identifier = @(object.identifier);
		dispatch_group_t group = dispatch_group_create();
		dispatch_group_enter(group);

		os_unfair_lock_lock(&_pendingInitsLock);
		_pendingInits[identifier] = group;
		os_unfair_lock_unlock(&_pendingInitsLock);

		[ZENDomainObject asyncInit:@[object] model:self.dataModel completion:^{
			os_unfair_lock_lock(&self->_pendingInitsLock);
			[self->_pendingInits removeObjectForKey:identifier];
			os_unfair_lock_unlock(&self->_pendingInitsLock);
			dispatch_group_leave(group);
		}];
	}
}

- (void)deliverObjects:(NSArray *)objects whenInitialized:(ZENFetchResultsBlock)resultsBlock {
	dispatch_group_t initialized = dispatch_group_create();
	dispatch_queue_t threadPool = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0);

	os_unfair_lock_lock(&_pendingInitsLock);
	for (id<ZENIdentifiable> object in objects) {
		dispatch_group_t pending = _pendingInits[@(object.identifier)];
		if (pending) {
			dispatch_group_enter(initialized);
			dispatch_group_notify(pending, threadPool, ^{
				dispatch_group_leave(initialized);
			});
		}
	}
	os_unfair_lock_unlock(&_pendingInitsLock);

	dispatch_group_notify(initialized, threadPool, ^{
		ZENCallFetchResultsBlockOnThreadPool(resultsBlock, objects);
	});
}

#pragma mark - Count

- (void)countAllObjects:(ZENAsyncCountCompletionBlock)countBlock {
	[self.queue fetchAsync:^(ZENDatabase *database) {
		NSUInteger count = [self.table countAllRows:database];
		ZENCallAsyncCountCompletionBlockOnThreadPool(countBlock, count);
	}];
}

- (void)countAllObjectsForUI:(ZENAsyncCountCompletionBlock)countBlock {
	// Bounce to main thread
	[self countAllObjects:^(NSUInteger count) {
		ZENCallAsyncCountCompletionBlockOnMainThread(countBlock, count);
	}];
}

#pragma mark - Sum

- (void)sumColumn:(NSString *)columnName
	   completion:(ZENAsyncCountCompletionBlock)sumBlock {
	// Identifiers can't be bound as SQL parameters, so they go into the statement
	Class<ZENDatabaseTable> tableClass = [self.table class];
	NSString *sql = [NSString stringWithFormat:@"SELECT SUM(%@) FROM %@;", columnName, [tableClass tableName]];

	[self.queue fetchAsync:^(ZENDatabase *database) {
		NSUInteger sum = 0;
		ZENResultSet *rs = [database executeQuery:sql];
		if ([rs next]) {
			// SUM() over no rows is NULL, which reads as 0
			sum = (NSUInteger)[rs longLongIntForColumnIndex:0];
		}
		[rs close];
		ZENCallAsyncCountCompletionBlockOnThreadPool(sumBlock, sum);
	}];
}

- (void)sumColumn:(NSString *)columnName
	 uiCompletion:(ZENAsyncCountCompletionBlock)sumBlock {
	// Bounce to main thread
	[self sumColumn:columnName
		 completion:^(NSUInteger sum) {
			 ZENCallAsyncCountCompletionBlockOnMainThread(sumBlock, sum);
		 }];
}

#pragma mark - Fetch

- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
					 completion:(ZENFetchResultsBlock)resultsBlock {
	// Check if this object is in the cache
	id<ZENIdentifiable> object = [self.cache cachedObject:identifier];
	if (object) {
		[self deliverObjects:@[object] whenInitialized:resultsBlock];
		return;
	}

	// Bounce to the database queue to fetch this object
	[self.queue fetchAsync:^(ZENDatabase *database) {
		// Check again if this object has shown up in the cache since we looked earlier
		id<ZENIdentifiable> object = [self.cache cachedObject:identifier];
		if (!object) {
			// Create the object, start its async init, then cache it. This is safe because this runs
			// on the database queue, and we only ever create and cache objects on this queue. If there
			// was a race, only one instance can win and cache the object. The other instance would have
			// a cache hit just before here.
			object = [self fetchObjectByIdentifier:identifier database:database];
			if (!object) {
				ZENCallFetchResultsBlockOnThreadPool(resultsBlock, @[]);
				return;
			}
			[self startAsyncInit:@[object]];
			[self.cache cacheObject:object];
		}

		[self deliverObjects:@[object] whenInitialized:resultsBlock];
	}];
}

- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
				   uiCompletion:(ZENFetchResultsBlock)resultsBlock {
	// Bounce to main thread
	[self fetchObjectByIdentifier:identifier completion:^(NSArray *fetchedObjects) {
		ZENCallFetchResultsBlockOnMainThread(resultsBlock, fetchedObjects);
	}];
}

- (void)fetchAllObjects:(ZENFetchResultsBlock)resultsBlock {
	// We can't rely on the cache for early return like in objectByIdentifier: because we don't know
	// the full list of the object identifiers without a query.
	[self.queue fetchAsync:^(ZENDatabase *database) {
		NSMutableArray *objects = [NSMutableArray array];
		NSMutableArray *newObjects = [NSMutableArray array];
		ZENResultSet *rs = [self.table allRows:database];
		while ([rs next]) {
			// Check if an object with this identifier is in the cache
			// TODO: Consider batching all identifiers together to a single cache call
			int64_t identifier = [rs longLongIntForColumnIndex:0];
			id<ZENIdentifiable> object = [self.cache cachedObject:identifier];

			if (!object) {
				ZENDataTransferObject *dto = [self.table dtoFromRow:rs];
				object = [[(Class)self.embryo alloc] initWithDTO:dto];
				[newObjects addObject:object];
			}

			[objects addObject:object];
		}
		[rs close];

		// Only objects new to the cache need async init; cached objects already
		// had theirs, or are still waiting on it. See above for note on thread safety.
		[self startAsyncInit:newObjects];
		for (id<ZENIdentifiable> object in newObjects) {
			[self.cache cacheObject:object];
		}

		[self deliverObjects:[objects copy] whenInitialized:resultsBlock];
	}];
}

- (void)fetchAllObjectsForUI:(ZENFetchResultsBlock)resultsBlock {
	// Bounce to main thread
	[self fetchAllObjects:^(NSArray *fetchedObjects) {
		ZENCallFetchResultsBlockOnMainThread(resultsBlock, fetchedObjects);
	}];
}

#pragma mark - Add

- (void)addObject:(ZENDomainObject *)domainObject
	   completion:(ZENAsyncContinueBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self.queue transactionAsync:^(ZENDatabase *database) {
		if ([self.table insertDTO:domainObject.basicDTO database:database]) {
			[self.cache cacheObject:domainObject];
			ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectAddedNotification, self, notificationData);
		}
		ZENCallAsyncContinueBlockOnThreadPool(completion);
	}];
}

- (void)addObject:(ZENDomainObject *)domainObject
	 uiCompletion:(ZENAsyncContinueBlock)completion {
	// Bounce to main thread
	[self addObject:domainObject completion:^{
		ZENCallAsyncContinueBlockOnMainThread(completion);
	}];
}

- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
			 completion:(ZENAsyncContinueBlock)completion {
	[domainObject.class asyncInit:@[domainObject] model:self.dataModel completion:^{
		[self addObject:domainObject completion:completion];
	}];
}

- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
		   uiCompletion:(ZENAsyncContinueBlock)completion {
	[self asyncInitAndAdd:domainObject completion:^{
		ZENCallAsyncContinueBlockOnMainThread(completion);
	}];
}

#pragma mark - Update

- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncContinueBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self.queue transactionAsync:^(ZENDatabase *database) {
		[self.table updateDTO:domainObject.basicDTO database:database];
		ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectUpdatedNotification, self, notificationData);
		ZENCallAsyncContinueBlockOnThreadPool(completion);
	}];
}

- (void)updateObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncContinueBlock)completion {
	// Bounce to main thread
	[self updateObject:domainObject completion:^{
		ZENCallAsyncContinueBlockOnMainThread(completion);
	}];
}

#pragma mark - Delete

- (void)deleteObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncContinueBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self.queue transactionAsync:^(ZENDatabase *database) {
		if ([self.table deleteByIdentifier:domainObject.identifier database:database]) {
			[self.cache removeObject:domainObject.identifier];
			ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectDeletedNotification, self, notificationData);
		}
		ZENCallAsyncContinueBlockOnThreadPool(completion);
	}];
}

- (void)deleteObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncContinueBlock)completion {
	// Bounce to main thread
	[self deleteObject:domainObject completion:^{
		ZENCallAsyncContinueBlockOnMainThread(completion);
	}];
}

#pragma mark - Notifications

- (void)zen_addObserver:(id)observer
			   selector:(SEL)selector {
	[NSNotificationCenter.defaultCenter addObserver:observer selector:selector name:ZENObjectRepositoryObjectAddedNotification object:self];
	[NSNotificationCenter.defaultCenter addObserver:observer selector:selector name:ZENObjectRepositoryObjectUpdatedNotification object:self];
	[NSNotificationCenter.defaultCenter addObserver:observer selector:selector name:ZENObjectRepositoryObjectDeletedNotification object:self];
}

- (void)zen_removeObserver:(id)observer {
	[NSNotificationCenter.defaultCenter removeObserver:observer name:ZENObjectRepositoryObjectAddedNotification object:self];
	[NSNotificationCenter.defaultCenter removeObserver:observer name:ZENObjectRepositoryObjectUpdatedNotification object:self];
	[NSNotificationCenter.defaultCenter removeObserver:observer name:ZENObjectRepositoryObjectDeletedNotification object:self];
}

@end

NSString *const ZENObjectRepositoryNotificationObjectKey = @"ZENObjectRepositoryNotificationObject";
NSString *const ZENObjectRepositoryObjectAddedNotification = @"ZENObjectRepositoryObjectAddedNotification";
NSString *const ZENObjectRepositoryObjectUpdatedNotification = @"ZENObjectRepositoryObjectUpdatedNotification";
NSString *const ZENObjectRepositoryObjectDeletedNotification = @"ZENObjectRepositoryObjectDeletedNotification";
