//
//  ObjectRepository.h
//  CoreZen
//
//  Created by Zach Nelson on 6/28/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/DomainObject.h>

@protocol ZENDataModel;
@protocol ZENDatabaseTable;
@class ZENDatabase;
@class ZENDatabaseQueue;
@class ZENResultSet;
@class ZENRepositoryWriteBatch;

NS_ASSUME_NONNULL_BEGIN

// Returns the rows for a fetch, or nil if its query fails. It runs on the
// repository's database queue, and gets the repository's table, so it can call
// a query method of the table's own: declare the parameter as the table's class.
typedef ZENResultSet *_Nullable (^ZENRepositoryQuery)(__kindof NSObject<ZENDatabaseTable> *table, ZENDatabase *database);

typedef enum : NSUInteger {
	ZENObjectRepositoryCacheType_Weak = 0,
	ZENObjectRepositoryCacheType_Strong = 1
} ZENObjectRepositoryCacheType;

@interface ZENObjectRepository : NSObject

#pragma mark - Init

- (instancetype)initWithDataModel:(nullable id<ZENDataModel>)dataModel
					   tableClass:(Class<ZENDatabaseTable>)tableClass
					databaseQueue:(ZENDatabaseQueue *)databaseQueue
			   domainObjectEmbryo:(Class<ZENDomainObject>)embryo
						cacheType:(ZENObjectRepositoryCacheType)cacheType;

#pragma mark - Count

// Runs asynchronously. Completion block happens on a thread pool.
- (void)countAllObjects:(ZENAsyncCountCompletionBlock)countBlock;

// Same as above, but resultsBlock happens on the main thread.
- (void)countAllObjectsForUI:(ZENAsyncCountCompletionBlock)countBlock;

#pragma mark - Sum

// Sum of an integer column over all objects, or 0 if there are none. columnName
// goes into the SQL as is, so it must be a column of this repository's table
// named in code, never user input. Runs asynchronously. Completion block
// happens on a thread pool.
- (void)sumColumn:(NSString *)columnName
	   completion:(ZENAsyncCountCompletionBlock)sumBlock;

// Same as above, but uiCompletion block happens on the main thread.
- (void)sumColumn:(NSString *)columnName
	 uiCompletion:(ZENAsyncCountCompletionBlock)sumBlock;

#pragma mark - Fetch

// Every fetch returns the repository's one object for each identifier: the one
// in its cache, or else a new one made from the row, which joins the cache.
// Fetched objects are delivered only after their async init has finished. Each
// object's performAsyncInit runs once, when the repository first creates it
// from the database; objects already in the cache aren't initialized again.
// An object whose async init fails is left out of the results and dropped from
// the cache, so a later fetch creates it again and retries its init.

// Runs asynchronously. Result callback block happens on a thread pool.
- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
					 completion:(ZENFetchResultsBlock)resultsBlock;

// Same as above, but uiCompletion block happens on the main thread.
- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
				   uiCompletion:(ZENFetchResultsBlock)resultsBlock;

// Runs asynchronously. Result callback block happens on a thread pool.
- (void)fetchAllObjects:(ZENFetchResultsBlock)resultsBlock;

// Same as above, but resultsBlock happens on the main thread.
- (void)fetchAllObjectsForUI:(ZENFetchResultsBlock)resultsBlock;

// Fetches the objects in the rows query returns, such as the ones that match a
// condition, in the order of their rows. Each object comes once, at its first
// row. The rows need the columns the table's dtoFromRow: reads, identifier
// first, as allRows: returns them. A failed query fetches no objects. With a
// table class that has a rowsInFolder:database: method, for example:
//
//   [repository fetchObjectsWithQuery:^ZENResultSet *(MyTable *table, ZENDatabase *database) {
//       return [table rowsInFolder:folder database:database];
//   } completion:^(NSArray *fetchedObjects) { ... }];
//
// Runs asynchronously. Result callback block happens on a thread pool.
- (void)fetchObjectsWithQuery:(ZENRepositoryQuery)query
				   completion:(ZENFetchResultsBlock)resultsBlock;

// Same as above, but uiCompletion block happens on the main thread.
- (void)fetchObjectsWithQuery:(ZENRepositoryQuery)query
				 uiCompletion:(ZENFetchResultsBlock)resultsBlock;

#pragma mark - Add, Update and Delete

// Each write is a transaction of its own. Its completion gets nil once the change
// is saved, or an error (in ZENDatabaseErrorDomain) when it was rolled back or
// never made. Only a saved change updates the cache and posts its notification.
// The completion may be nil.
// A failed update leaves the object's own properties as the caller set them.

// Runs asynchronously. Completion block happens on a thread pool.
- (void)addObject:(ZENDomainObject *)domainObject
	   completion:(ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)addObject:(ZENDomainObject *)domainObject
	 uiCompletion:(ZENAsyncCompletionBlock)completion;

// Helper method to call DomainObject +asyncInit: on object before
// adding to repository. If the object's async init fails, it isn't added, and
// completion gets the error; so does a failed add. Completion block happens on
// a thread pool.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
			 completion:(ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
		   uiCompletion:(ZENAsyncCompletionBlock)completion;

// Runs asynchronously. Completion block happens on a thread pool.
- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)updateObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion;

// Runs asynchronously. Completion block happens on a thread pool.
- (void)deleteObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)deleteObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion;

#pragma mark - Write Batches

// Saves several writes, to objects in one or more repositories, in one
// transaction. build stages them on the calling thread, before this returns.
// Completion gets nil once they're all saved: each repository has updated its
// cache and posted its notifications, in the order the writes were staged. Or it
// gets an error (in ZENDatabaseErrorDomain), and nothing has changed, in the
// database or in memory. Every repository in a batch must share one database
// queue. The completion may be nil. Completion block happens on a thread pool.
+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		   completion:(nullable ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		 uiCompletion:(nullable ZENAsyncCompletionBlock)completion;

#pragma mark - Notifications

// Notifications are delivered on the main thread
- (void)zen_addObserver:(id)observer
			   selector:(SEL)selector;

- (void)zen_removeObserver:(id)observer;

@end

// The writes for one +[ZENObjectRepository performWrites:completion:]. Stage at
// most one write for each object; a second one makes the batch fail.
@interface ZENRepositoryWriteBatch : NSObject

- (instancetype)init NS_UNAVAILABLE;

// Adds an object that's initialized already: its async init, if it has one, is
// done. Once saved, the repository caches it and posts it as added.
- (void)addObject:(ZENDomainObject *)domainObject toRepository:(ZENObjectRepository *)repository;

// Updates the object with this identifier, whether or not it's loaded. change
// gets a copy of its DTO to change: the loaded object's, or else one read from
// the database. It runs on the database queue, inside the transaction. Once
// saved, a loaded object's DTO takes the copy's values, its didUpdateDTO runs,
// and the repository posts it as updated. One that isn't loaded is only changed
// in the database. An identifier with no object makes the batch fail.
- (void)updateObjectWithIdentifier:(ZENIdentifier)identifier
					  inRepository:(ZENObjectRepository *)repository
							change:(void (^)(__kindof ZENDataTransferObject *dto))change;

// Deletes the object with this identifier. Once saved, a loaded object leaves
// the cache, and the repository posts it as deleted.
- (void)deleteObjectWithIdentifier:(ZENIdentifier)identifier fromRepository:(ZENObjectRepository *)repository;

@end


extern NSString *const ZENObjectRepositoryNotificationObjectKey;

extern NSString *const ZENObjectRepositoryObjectAddedNotification;
extern NSString *const ZENObjectRepositoryObjectUpdatedNotification;
extern NSString *const ZENObjectRepositoryObjectDeletedNotification;

NS_ASSUME_NONNULL_END
