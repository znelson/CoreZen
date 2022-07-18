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
#import "DomainCommon.h"

@import FMDB;

@interface ZENObjectRepository ()

@property (nonatomic, strong, readonly) NSObject<ZENDatabaseTable> *table;
@property (nonatomic, strong, readonly) ZENDatabaseQueue *queue;
@property (nonatomic, strong, readonly) Class<ZENDomainObject> embryo;
@property (nonatomic, strong, readonly) ZENObjectCache *cache;
@property (nonatomic, weak, readonly) id<ZENDataModel> dataModel;

// Runs asynchronously on a thread pool.

// Runs synchronously. To be called on database queue.
- (id<ZENIdentifiable>)createObjectFromRow:(FMResultSet *)row;

// Runs synchronously. To be called on database queue.
- (id<ZENIdentifiable>)fetchObjectByIdentifier:(ZENIdentifier)identifier
									  database:(FMDatabase *)database;

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
		_dataModel = dataModel;
		_table = [(Class)tableClass new];
		_queue = databaseQueue;
		_embryo = embryo;
		_cache = (cacheType == ZENObjectRepositoryCacheType_Strong) ? [ZENObjectCache strongObjectCache] : [ZENObjectCache weakObjectCache];
	}
	return self;
}

#pragma mark - [private] Create

- (id<ZENIdentifiable>)createObjectFromRow:(FMResultSet *)row {
	ZENDataTransferObject *dto = [self.table dtoFromRow:row];
	id<ZENIdentifiable> object = [[(Class)self.embryo alloc] initWithDTO:dto];
	return object;
}

#pragma mark - [private] Fetch

- (id<ZENIdentifiable>)fetchObjectByIdentifier:(ZENIdentifier)identifier
									  database:(FMDatabase *)database {

	FMResultSet *rs = [self.table rowByIdentifier:identifier database:database];
	id<ZENIdentifiable> object = nil;
	if ([rs next]) {
		object = [self createObjectFromRow:rs];
	}
	[rs close];
	return object;
}

#pragma mark - Count

- (void)countAllObjects:(ZENAsyncCountCompletionBlock)countBlock {
	[self.queue fetchAsync:^(FMDatabase *database) {
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

- (void)sumAllVideoDuration:(ZENAsyncCountCompletionBlock)countBlock {
	if ([self.table respondsToSelector:@selector(sumAllVideoDuration:)]) {
		[self.queue fetchAsync:^(FMDatabase *database) {
			NSUInteger count = [self.table sumAllVideoDuration:database];
			ZENCallAsyncCountCompletionBlockOnThreadPool(countBlock, count);
		}];
	} else {
		ZENCallAsyncCountCompletionBlockOnThreadPool(countBlock, 0);
	}
}

- (void)sumAllVideoDurationForUI:(ZENAsyncCountCompletionBlock)countBlock {
	// Bounce to main thread
	[self sumAllVideoDuration:^(NSUInteger count) {
		ZENCallAsyncCountCompletionBlockOnMainThread(countBlock, 0);
	}];
}

#pragma mark - Fetch

- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
					 completion:(ZENFetchResultsBlock)resultsBlock {
	
	// Check if this object is in the cache
	id<ZENIdentifiable> object = [self.cache cachedObject:identifier];
	if (object) {
		ZENCallFetchResultsBlockOnThreadPool(resultsBlock, @[object]);
		return;
	}
	
	// Bounce to the database queue to fetch this object
	[self.queue fetchAsync:^(FMDatabase *database) {
		
		// Check again if this object has shown up in the cache since we looked earlier
		id<ZENIdentifiable> object = [self.cache cachedObject:identifier];
		if (object) {
			ZENCallFetchResultsBlockOnThreadPool(resultsBlock, @[object]);
			return;
		}
		
		// Create the object, then cache it. This is safe becuase this running on the database queue
		// and we only ever create and cache objects on this queue. If there was a race, only one instance
		// can win and cache the object. The other instance would have a cache hit just before here.
		object = [self fetchObjectByIdentifier:identifier database:database];
		[self.cache cacheObject:object];
		
		// Async initialize object
		NSArray *fetchedObjects = @[object];
		[ZENDomainObject asyncInit:fetchedObjects model:self.dataModel completion:^{
			ZENCallFetchResultsBlockOnThreadPool(resultsBlock, fetchedObjects);
		}];
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
	[self.queue fetchAsync:^(FMDatabase *database) {
		NSMutableArray *objects = [NSMutableArray array];
		FMResultSet *rs = [self.table allRows:database];
		while ([rs next]) {
			// Check if an object with this identifier is in the cache
			// TODO: Consider batching all identifiers together to a single cache call
			int64_t identifier = [rs longLongIntForColumnIndex:0];
			id<ZENIdentifiable> object = [self.cache cachedObject:identifier];

			if (!object) {
				// Create the object, then cache it. See above for note on thread safety.
				ZENDataTransferObject *dto = [self.table dtoFromRow:rs];
				object = [[(Class)self.embryo alloc] initWithDTO:dto];
				[self.cache cacheObject:object];
			}

			[objects addObject:object];
		}
		[rs close];
		
		// Async initialize objects
		NSArray *fetchedObjects = [objects copy];
		[ZENDomainObject asyncInit:fetchedObjects model:self.dataModel completion:^{
			ZENCallFetchResultsBlockOnThreadPool(resultsBlock, fetchedObjects);
		}];
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
	
	[self.cache cacheObject:domainObject];
	[self.queue transactionAsync:^(FMDatabase *database) {
		[self.table insertDTO:domainObject.basicDTO database:database];
		ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectAddedNotification, self, notificationData);
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

- (void) asyncInitAndAdd:(ZENDomainObject *)domainObject
			  completion:(ZENAsyncContinueBlock)completion {
	[domainObject.class asyncInit:@[domainObject] model:self.dataModel completion:^{
		[self addObject:domainObject completion:completion];
	}];
}

- (void) asyncInitAndAdd:(ZENDomainObject *)domainObject
			uiCompletion:(ZENAsyncContinueBlock)completion {
	[self asyncInitAndAdd:domainObject completion:^{
			ZENCallAsyncContinueBlockOnThreadPool(completion);
	}];
}

#pragma mark - Update

- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncContinueBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};
	
	[self.queue transactionAsync:^(FMDatabase *database) {
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

	[self.cache removeObject:domainObject.identifier];
	[self.queue transactionAsync:^(FMDatabase *database) {
		[self.table deleteByIdentifier:domainObject.identifier database:database];
		ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectDeletedNotification, self, notificationData);
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

NSString *ZENObjectRepositoryNotificationObjectKey = @"ZENObjectRepositoryNotificationObject";
NSString *ZENObjectRepositoryObjectAddedNotification = @"ZENObjectRepositoryObjectAddedNotification";
NSString *ZENObjectRepositoryObjectUpdatedNotification = @"ZENObjectRepositoryObjectUpdatedNotification";
NSString *ZENObjectRepositoryObjectDeletedNotification = @"ZENObjectRepositoryObjectDeletedNotification";
