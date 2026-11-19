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
#import "Database+Private.h"
#import "ResultSet.h"
#import "DomainCommon.h"

#import <os/lock.h>

typedef NS_ENUM(NSInteger, ZENStagedWriteKind) {
	ZENStagedWriteKindAdd,
	ZENStagedWriteKindUpdate,
	ZENStagedWriteKindDelete,
};

// One write in a batch
@interface ZENStagedWrite : NSObject

@property (nonatomic) ZENStagedWriteKind kind;
@property (nonatomic, strong) ZENObjectRepository *repository;
@property (nonatomic) ZENIdentifier identifier;
// The object to add
@property (nonatomic, strong) ZENDomainObject *object;
// How to change the DTO of the object to update
@property (nonatomic, copy) void (^change)(__kindof ZENDataTransferObject *dto);

@end

@implementation ZENStagedWrite
@end

@interface ZENRepositoryWriteBatch ()

@property (nonatomic, strong, readonly) NSMutableArray<ZENStagedWrite *> *writes;

- (instancetype)initForStaging;

@end

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

// To be called on database queue, with objects that aren't cached yet.
- (void)cacheAndStartAsyncInit:(NSArray *)objects;

// Runs write in a transaction of its own. Once it has committed, and write
// returned YES, calls saved on the database queue. Then calls completion with
// nil, or with an error if the change wasn't saved.
- (void)write:(BOOL (^)(ZENDatabase *database))write
		 saved:(void (^)(void))saved
	completion:(ZENAsyncCompletionBlock)completion;

- (void)deliverObjects:(NSArray *)objects whenInitialized:(ZENFetchResultsBlock)resultsBlock;

// Runs synchronously. To be called on database queue. The DTO in the row with this
// identifier, or nil if there isn't one.
- (ZENDataTransferObject *)dtoWithIdentifier:(ZENIdentifier)identifier
									database:(ZENDatabase *)database;

// Makes one of a batch's writes, inside its transaction on the database queue.
// Returns what to do once the batch is saved, or nil, with *error set, if the
// table couldn't make the write.
- (void (^)(void))makeStagedWrite:(ZENStagedWrite *)write
						 database:(ZENDatabase *)database
							error:(NSError **)error;

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

- (void)cacheAndStartAsyncInit:(NSArray *)objects {
	for (id<ZENDomainObject> object in objects) {
		NSNumber *identifier = @(object.identifier);
		dispatch_group_t group = dispatch_group_create();
		dispatch_group_enter(group);

		// Register the init before caching the object, so a fetch that finds it in
		// the cache also finds its init in progress. Cache it before starting the
		// init, so a failed init can't finish before the object is cached.
		os_unfair_lock_lock(&_pendingInitsLock);
		_pendingInits[identifier] = group;
		os_unfair_lock_unlock(&_pendingInitsLock);
		[self.cache cacheObject:object];

		[ZENDomainObject asyncInit:@[object]
							 model:self.dataModel
						completion:^(NSError *error) {
							if (error) {
								// Drop the object, so fetches leave it out. A later fetch creates it
								// again from the database and retries its init.
								NSLog(@"Async init failed for %@: %@", object, error);
								if ([self.cache cachedObject:object.identifier] == object) {
									[self.cache removeObject:object.identifier];
								}
							}

							// A fetch after a failure may have registered a new init for this identifier
							os_unfair_lock_lock(&self->_pendingInitsLock);
							if (self->_pendingInits[identifier] == group) {
								[self->_pendingInits removeObjectForKey:identifier];
							}
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
		// An object whose init failed was dropped from the cache, so leave it out
		NSMutableArray *initializedObjects = [NSMutableArray arrayWithCapacity:objects.count];
		for (id<ZENIdentifiable> object in objects) {
			if ([self.cache cachedObject:object.identifier] == object) {
				[initializedObjects addObject:object];
			}
		}
		ZENCallFetchResultsBlockOnThreadPool(resultsBlock, initializedObjects);
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
			// Create the object, cache it, then start its async init. This is safe because this runs
			// on the database queue, and we only ever create and cache objects on this queue. If there
			// was a race, only one instance can win and cache the object. The other instance would have
			// a cache hit just before here.
			object = [self fetchObjectByIdentifier:identifier database:database];
			if (!object) {
				ZENCallFetchResultsBlockOnThreadPool(resultsBlock, @[]);
				return;
			}
			[self cacheAndStartAsyncInit:@[object]];
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
		[self cacheAndStartAsyncInit:newObjects];

		[self deliverObjects:[objects copy] whenInitialized:resultsBlock];
	}];
}

- (void)fetchAllObjectsForUI:(ZENFetchResultsBlock)resultsBlock {
	// Bounce to main thread
	[self fetchAllObjects:^(NSArray *fetchedObjects) {
		ZENCallFetchResultsBlockOnMainThread(resultsBlock, fetchedObjects);
	}];
}

#pragma mark - Add, Update and Delete

- (void)write:(BOOL (^)(ZENDatabase *database))write
		 saved:(void (^)(void))saved
	completion:(ZENAsyncCompletionBlock)completion {
	__block BOOL written = NO;
	[self.queue transactionAsync:^(ZENDatabase *database) {
		written = write(database);
	}
		result:^(NSError *error) {
			if (!error && !written) {
				error = ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, @"The table couldn't write the object");
			}
			if (error) {
				NSLog(@"ERROR: A write to %@ wasn't saved: %@", [[self.table class] tableName], error.localizedDescription);
			} else {
				// Still on the database queue, so the cache keeps step with the
				// database for the next block that runs there
				saved();
			}
			ZENCallAsyncCompletionBlockOnThreadPool(completion, error);
		}];
}

- (void)addObject:(ZENDomainObject *)domainObject
	   completion:(ZENAsyncCompletionBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self write:^BOOL(ZENDatabase *database) {
		return [self.table insertDTO:domainObject.basicDTO database:database];
	}
		saved:^{
			[self.cache cacheObject:domainObject];
			ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectAddedNotification, self, notificationData);
		}
		completion:completion];
}

- (void)addObject:(ZENDomainObject *)domainObject
	 uiCompletion:(ZENAsyncCompletionBlock)completion {
	// Bounce to main thread
	[self addObject:domainObject
		 completion:^(NSError *error) {
			 ZENCallAsyncCompletionBlockOnMainThread(completion, error);
		 }];
}

- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
			 completion:(ZENAsyncCompletionBlock)completion {
	[domainObject.class asyncInit:@[domainObject]
							model:self.dataModel
					   completion:^(NSError *error) {
						   if (error) {
							   // Don't add an object whose init failed
							   ZENCallAsyncCompletionBlockOnThreadPool(completion, error);
							   return;
						   }
						   [self addObject:domainObject completion:completion];
					   }];
}

- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
		   uiCompletion:(ZENAsyncCompletionBlock)completion {
	[self asyncInitAndAdd:domainObject
			   completion:^(NSError *error) {
				   ZENCallAsyncCompletionBlockOnMainThread(completion, error);
			   }];
}

- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self write:^BOOL(ZENDatabase *database) {
		return [self.table updateDTO:domainObject.basicDTO database:database];
	}
		saved:^{
			[domainObject didUpdateDTO];
			ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectUpdatedNotification, self, notificationData);
		}
		completion:completion];
}

- (void)updateObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion {
	// Bounce to main thread
	[self updateObject:domainObject
			completion:^(NSError *error) {
				ZENCallAsyncCompletionBlockOnMainThread(completion, error);
			}];
}

- (void)deleteObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion {
	NSDictionary *notificationData = @{
		ZENObjectRepositoryNotificationObjectKey: domainObject
	};

	[self write:^BOOL(ZENDatabase *database) {
		return [self.table deleteByIdentifier:domainObject.identifier database:database];
	}
		saved:^{
			[self.cache removeObject:domainObject.identifier];
			ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectDeletedNotification, self, notificationData);
		}
		completion:completion];
}

- (void)deleteObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion {
	// Bounce to main thread
	[self deleteObject:domainObject
			completion:^(NSError *error) {
				ZENCallAsyncCompletionBlockOnMainThread(completion, error);
			}];
}

#pragma mark - Write Batches

+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		   completion:(ZENAsyncCompletionBlock)completion {
	ZENRepositoryWriteBatch *batch = [[ZENRepositoryWriteBatch alloc] initForStaging];
	build(batch);
	NSArray<ZENStagedWrite *> *writes = [batch.writes copy];
	if (writes.count == 0) {
		ZENCallAsyncCompletionBlockOnThreadPool(completion, nil);
		return;
	}

	// One transaction needs one database, and each object gets one write
	ZENDatabaseQueue *queue = writes.firstObject.repository.queue;
	NSMutableSet<NSString *> *writtenObjects = [NSMutableSet set];
	for (ZENStagedWrite *write in writes) {
		NSString *tableName = [[write.repository.table class] tableName];
		NSString *writtenObject = [NSString stringWithFormat:@"%@ %lld", tableName, write.identifier];
		NSString *description = nil;
		if (write.repository.queue != queue) {
			description = @"The repositories in a write batch don't share a database queue";
		} else if ([writtenObjects containsObject:writtenObject]) {
			description = [NSString stringWithFormat:@"A write batch has more than one write for object %lld in %@", write.identifier, tableName];
		}
		if (description) {
			NSLog(@"ERROR: %@", description);
			ZENCallAsyncCompletionBlockOnThreadPool(completion, ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, description));
			return;
		}
		[writtenObjects addObject:writtenObject];
	}

	// Filled in on the database queue, inside the transaction, and used once it's saved
	NSMutableArray<void (^)(void)> *savedBlocks = [NSMutableArray arrayWithCapacity:writes.count];
	__block NSError *writeError = nil;
	[queue transactionAsync:^(ZENDatabase *database) {
		for (ZENStagedWrite *write in writes) {
			void (^saved)(void) = [write.repository makeStagedWrite:write database:database error:&writeError];
			if (!saved) {
				// Undo the batch's earlier writes too
				[database cancelTransaction];
				return;
			}
			[savedBlocks addObject:saved];
		}
	}
		result:^(NSError *error) {
			// A failed statement explains itself. Otherwise a table didn't make a write,
			// which canceled the transaction.
			if (writeError && (!error || error.code == ZENDatabaseErrorTransactionCanceled)) {
				error = writeError;
			}
			if (error) {
				NSLog(@"ERROR: A write batch wasn't saved: %@", error.localizedDescription);
				ZENCallAsyncCompletionBlockOnThreadPool(completion, error);
				return;
			}
			// Still on the database queue, so caches keep step with the database for
			// the next block that runs there
			for (void (^saved)(void) in savedBlocks) {
				saved();
			}
			ZENCallAsyncCompletionBlockOnThreadPool(completion, nil);
		}];
}

+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		 uiCompletion:(ZENAsyncCompletionBlock)completion {
	[self performWrites:build
			 completion:^(NSError *error) {
				 ZENCallAsyncCompletionBlockOnMainThread(completion, error);
			 }];
}

- (ZENDataTransferObject *)dtoWithIdentifier:(ZENIdentifier)identifier
									database:(ZENDatabase *)database {
	ZENResultSet *rs = [self.table rowByIdentifier:identifier database:database];
	ZENDataTransferObject *dto = [rs next] ? [self.table dtoFromRow:rs] : nil;
	[rs close];
	return dto;
}

- (void (^)(void))makeStagedWrite:(ZENStagedWrite *)write
						 database:(ZENDatabase *)database
							error:(NSError **)error {
	NSString *tableName = [[self.table class] tableName];
	switch (write.kind) {
		case ZENStagedWriteKindAdd: {
			ZENDomainObject *object = write.object;
			if (![self.table insertDTO:object.basicDTO database:database]) {
				if (error) {
					*error = ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, [NSString stringWithFormat:@"%@ couldn't add object %lld", tableName, write.identifier]);
				}
				return nil;
			}
			return ^{
				[self.cache cacheObject:object];
				ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectAddedNotification, self, @{ ZENObjectRepositoryNotificationObjectKey: object });
			};
		}
		case ZENStagedWriteKindUpdate: {
			// Objects are only made and cached on the database queue, so whether this
			// one is loaded can't change before the batch is saved
			ZENDomainObject *object = [self.cache cachedObject:write.identifier];
			ZENDataTransferObject *dto = [object.basicDTO copy] ?: [self dtoWithIdentifier:write.identifier database:database];
			if (!dto) {
				if (error) {
					*error = ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, [NSString stringWithFormat:@"%@ has no object %lld to update", tableName, write.identifier]);
				}
				return nil;
			}
			write.change(dto);
			if (![self.table updateDTO:dto database:database]) {
				if (error) {
					*error = ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, [NSString stringWithFormat:@"%@ couldn't update object %lld", tableName, write.identifier]);
				}
				return nil;
			}
			if (!object) {
				// Only the row changes; a later fetch loads the new values
				return ^{
				};
			}
			return ^{
				[object.basicDTO takeValuesFromDTO:dto];
				[object didUpdateDTO];
				ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectUpdatedNotification, self, @{ ZENObjectRepositoryNotificationObjectKey: object });
			};
		}
		case ZENStagedWriteKindDelete: {
			if (![self.table deleteByIdentifier:write.identifier database:database]) {
				if (error) {
					*error = ZENDatabaseErrorMake(ZENDatabaseErrorWriteFailed, [NSString stringWithFormat:@"%@ couldn't delete object %lld", tableName, write.identifier]);
				}
				return nil;
			}
			return ^{
				ZENDomainObject *object = [self.cache cachedObject:write.identifier];
				if (object) {
					[self.cache removeObject:write.identifier];
					ZENDeliverNotificationOnMainThread(ZENObjectRepositoryObjectDeletedNotification, self, @{ ZENObjectRepositoryNotificationObjectKey: object });
				}
			};
		}
	}
	return nil;
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

#pragma mark - ZENRepositoryWriteBatch

@implementation ZENRepositoryWriteBatch

- (instancetype)initForStaging {
	self = [super init];
	if (self) {
		_writes = [NSMutableArray array];
	}
	return self;
}

- (void)addObject:(ZENDomainObject *)domainObject toRepository:(ZENObjectRepository *)repository {
	ZENStagedWrite *write = [ZENStagedWrite new];
	write.kind = ZENStagedWriteKindAdd;
	write.repository = repository;
	write.identifier = domainObject.identifier;
	write.object = domainObject;
	[self.writes addObject:write];
}

- (void)updateObjectWithIdentifier:(ZENIdentifier)identifier
					  inRepository:(ZENObjectRepository *)repository
							change:(void (^)(__kindof ZENDataTransferObject *dto))change {
	ZENStagedWrite *write = [ZENStagedWrite new];
	write.kind = ZENStagedWriteKindUpdate;
	write.repository = repository;
	write.identifier = identifier;
	write.change = change;
	[self.writes addObject:write];
}

- (void)deleteObjectWithIdentifier:(ZENIdentifier)identifier fromRepository:(ZENObjectRepository *)repository {
	ZENStagedWrite *write = [ZENStagedWrite new];
	write.kind = ZENStagedWriteKindDelete;
	write.repository = repository;
	write.identifier = identifier;
	[self.writes addObject:write];
}

@end
