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

/// A block that returns the rows for a repository's fetch, or nil if its query
/// fails.
///
/// It runs on the repository's database queue, and gets the repository's table,
/// so it can call a query method of the table's own: declare the parameter as
/// the table's class.
typedef ZENResultSet *_Nullable (^ZENRepositoryQuery)(__kindof NSObject<ZENDatabaseTable> *table, ZENDatabase *database);

/// How a repository's cache holds its objects.
typedef enum : NSUInteger {
	/// The cache holds an object only while something else holds it too. A
	/// fetch after it's released makes a new one from its row.
	ZENObjectRepositoryCacheType_Weak = 0,
	/// The cache holds every object the repository has loaded or added, until
	/// it's deleted.
	ZENObjectRepositoryCacheType_Strong = 1
} ZENObjectRepositoryCacheType;

/// Loads, caches and saves the objects stored in one table, asynchronously.
///
/// A repository combines a table class, a database queue and a cache. The cache
/// holds one object for each identifier, so every part of an app sees the same
/// one.
///
/// Every method is asynchronous. Each has two forms: one calls its block on a
/// background thread, and the other, named with `uiCompletion:` or `ForUI`,
/// calls it on the main thread.
///
/// ### Fetching
///
/// Every fetch returns the repository's one object for each identifier: the one
/// in its cache, or else a new one made from the row, which joins the cache.
/// Fetched objects are delivered only after their async init has finished. Each
/// object's ``ZENDomainObject-c.protocol/performAsyncInit:completion:`` runs
/// once, when the repository first creates it from the database; objects already
/// in the cache aren't initialized again. An object whose async init fails is
/// left out of the results and dropped from the cache, so a later fetch creates
/// it again and retries its init. A fetch whose query fails delivers no objects.
///
/// ### Saving
///
/// Each add, update or delete is a transaction of its own. Its completion gets
/// nil once the change is saved, or an error in ``ZENDatabaseErrorDomain`` when
/// it was rolled back or never made. Only a saved change updates the cache and
/// posts its notification. A failed update leaves the object's own properties as
/// the caller set them. To save several writes in one transaction, use
/// ``performWrites:completion:``.
@interface ZENObjectRepository : NSObject

#pragma mark - Init

/// Makes a repository for the objects stored in one table.
///
/// - Parameters:
///   - dataModel: The object the repository passes to each object's async init,
///     such as the app's model.
///   - tableClass: The table's class. The repository makes one instance of it.
///   - databaseQueue: The queue for the database the table is in.
///   - embryo: The class of the repository's objects, which it makes from DTOs
///     with ``ZENDomainObject-c.protocol/initWithDTO:``.
///   - cacheType: Whether the repository's cache holds its objects weakly or
///     strongly.
- (instancetype)initWithDataModel:(nullable id<ZENDataModel>)dataModel
					   tableClass:(Class<ZENDatabaseTable>)tableClass
					databaseQueue:(ZENDatabaseQueue *)databaseQueue
			   domainObjectEmbryo:(Class<ZENDomainObject>)embryo
						cacheType:(ZENObjectRepositoryCacheType)cacheType;

#pragma mark - Count

/// Counts the objects in the table, and calls a block with the count on a background thread.
- (void)countAllObjects:(ZENAsyncCountCompletionBlock)countBlock;

/// Counts the objects in the table, and calls a block with the count on the main thread.
- (void)countAllObjectsForUI:(ZENAsyncCountCompletionBlock)countBlock;

#pragma mark - Sum

/// Adds up an integer column over all the objects, and calls a block with the sum
/// on a background thread.
///
/// The sum is 0 if there are no objects. The column name goes into the SQL as
/// is, so it must be a column of this repository's table named in code, never
/// user input.
- (void)sumColumn:(NSString *)columnName
	   completion:(ZENAsyncCountCompletionBlock)sumBlock;

/// Adds up an integer column over all the objects, and calls a block with the sum
/// on the main thread.
///
/// Like ``sumColumn:completion:``, the column name must be named in code, never
/// user input.
- (void)sumColumn:(NSString *)columnName
	 uiCompletion:(ZENAsyncCountCompletionBlock)sumBlock;

#pragma mark - Fetch

// Fetches deliver objects only once their async init has finished. The class
// documentation above says more.

/// Fetches the object with an identifier, and calls a block on a background thread with an
/// array of it, or an empty array if there's none.
- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
					 completion:(ZENFetchResultsBlock)resultsBlock;

/// Fetches the object with an identifier, and calls a block on the main thread with an
/// array of it, or an empty array if there's none.
- (void)fetchObjectByIdentifier:(ZENIdentifier)identifier
				   uiCompletion:(ZENFetchResultsBlock)resultsBlock;

/// Fetches every object in the table, and calls a block with them on a background thread.
- (void)fetchAllObjects:(ZENFetchResultsBlock)resultsBlock;

/// Fetches every object in the table, and calls a block with them on the main thread.
- (void)fetchAllObjectsForUI:(ZENFetchResultsBlock)resultsBlock;

/// Fetches the objects in the rows a query returns, and calls a block with them
/// on a background thread.
///
/// The query can find the objects that match a condition, for example, and they
/// come in the order of their rows. Each object comes once, at its first row.
/// The rows need the columns the table's ``ZENDatabaseTable/dtoFromRow:`` reads,
/// identifier first, as ``ZENDatabaseTable/allRows:`` returns them. A failed
/// query fetches no objects. With a table class that has a
/// `rowsInFolder:database:` method, for example:
///
/// ```objc
/// [repository fetchObjectsWithQuery:^ZENResultSet *(MyTable *table, ZENDatabase *database) {
///     return [table rowsInFolder:folder database:database];
/// } completion:^(NSArray *fetchedObjects) { ... }];
/// ```
- (void)fetchObjectsWithQuery:(ZENRepositoryQuery)query
				   completion:(ZENFetchResultsBlock)resultsBlock;

/// Fetches the objects in the rows a query returns, and calls a block with them
/// on the main thread.
///
/// The query works as it does for ``fetchObjectsWithQuery:completion:``.
- (void)fetchObjectsWithQuery:(ZENRepositoryQuery)query
				 uiCompletion:(ZENFetchResultsBlock)resultsBlock;

#pragma mark - Add, Update and Delete

// Each write is a transaction of its own. The class documentation above says
// more.

/// Saves a new object, then calls a block on a background thread with nil, or the error.
///
/// Once the object is saved, the repository caches it and posts
/// ``ZENObjectRepositoryObjectAddedNotification``.
- (void)addObject:(ZENDomainObject *)domainObject
	   completion:(ZENAsyncCompletionBlock)completion;

/// Saves a new object, then calls a block on the main thread with nil, or the error.
///
/// Once the object is saved, the repository caches it and posts
/// ``ZENObjectRepositoryObjectAddedNotification``.
- (void)addObject:(ZENDomainObject *)domainObject
	 uiCompletion:(ZENAsyncCompletionBlock)completion;

/// Runs a new object's async init, then saves it, then calls a block on a background thread
/// with nil, or the error.
///
/// If the object's async init fails, it isn't saved, and the block gets the
/// init's error.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
			 completion:(ZENAsyncCompletionBlock)completion;

/// Runs a new object's async init, then saves it, then calls a block on the main thread
/// with nil, or the error.
///
/// If the object's async init fails, it isn't saved, and the block gets the
/// init's error.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
		   uiCompletion:(ZENAsyncCompletionBlock)completion;

/// Saves the values in an object's DTO, then calls a block on a background thread with nil,
/// or the error.
///
/// Once the change is saved, the object's ``ZENDomainObject-c.class/didUpdateDTO``
/// runs, and the repository posts ``ZENObjectRepositoryObjectUpdatedNotification``.
- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion;

/// Saves the values in an object's DTO, then calls a block on the main thread with nil,
/// or the error.
///
/// Once the change is saved, the object's ``ZENDomainObject-c.class/didUpdateDTO``
/// runs, and the repository posts ``ZENObjectRepositoryObjectUpdatedNotification``.
- (void)updateObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion;

/// Deletes an object, then calls a block on a background thread with nil, or the error.
///
/// Once the deletion is saved, the object leaves the cache, and the repository
/// posts ``ZENObjectRepositoryObjectDeletedNotification``.
- (void)deleteObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncCompletionBlock)completion;

/// Deletes an object, then calls a block on the main thread with nil, or the error.
///
/// Once the deletion is saved, the object leaves the cache, and the repository
/// posts ``ZENObjectRepositoryObjectDeletedNotification``.
- (void)deleteObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncCompletionBlock)completion;

#pragma mark - Write Batches

/// Saves several writes, to objects in one or more repositories, in one
/// transaction, then calls a block on a background thread with nil, or the error.
///
/// The build block stages the writes in a batch, on the calling thread, before
/// this returns. Completion gets nil once they're all saved: each repository has
/// updated its cache and posted its notifications, in the order the writes were
/// staged. Or it gets an error in ``ZENDatabaseErrorDomain``, and nothing has
/// changed, in the database or in memory. Every repository in a batch must share
/// one database queue. The completion may be nil.
+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		   completion:(nullable ZENAsyncCompletionBlock)completion;

/// Saves several writes in one transaction, then calls a block on the main thread with
/// nil, or the error.
///
/// The writes work as they do for ``performWrites:completion:``.
+ (void)performWrites:(void(NS_NOESCAPE ^)(ZENRepositoryWriteBatch *batch))build
		 uiCompletion:(nullable ZENAsyncCompletionBlock)completion;

#pragma mark - Notifications

/// Registers an observer for the repository's added, updated and deleted
/// notifications.
///
/// The notifications arrive on the main thread, and the selector gets each one
/// as its argument.
- (void)zen_addObserver:(id)observer
			   selector:(SEL)selector;

/// Removes an observer from the repository's notifications.
- (void)zen_removeObserver:(id)observer;

@end

/// The writes for one ``ZENObjectRepository/performWrites:completion:``.
///
/// Stage at most one write for each object; a second one makes the batch fail.
@interface ZENRepositoryWriteBatch : NSObject

- (instancetype)init NS_UNAVAILABLE;

/// Adds an object that's initialized already: its async init, if it has one,
/// is done.
///
/// Once saved, the repository caches it and posts it as added.
- (void)addObject:(ZENDomainObject *)domainObject toRepository:(ZENObjectRepository *)repository;

/// Updates the object with an identifier, whether or not it's loaded.
///
/// The change block gets a copy of the object's DTO to change: the loaded
/// object's, or else one read from the database. It runs on the database queue,
/// inside the transaction. Once saved, a loaded object's DTO takes the copy's
/// values, its ``ZENDomainObject-c.class/didUpdateDTO`` runs, and the repository
/// posts it as updated. One that isn't loaded is only changed in the database.
/// An identifier with no object makes the batch fail.
- (void)updateObjectWithIdentifier:(ZENIdentifier)identifier
					  inRepository:(ZENObjectRepository *)repository
							change:(void (^)(__kindof ZENDataTransferObject *dto))change;

/// Deletes the object with an identifier.
///
/// Once saved, a loaded object leaves the cache, and the repository posts it as
/// deleted.
- (void)deleteObjectWithIdentifier:(ZENIdentifier)identifier fromRepository:(ZENObjectRepository *)repository;

@end


/// The key in a repository notification's user info for the object it's about.
extern NSString *const ZENObjectRepositoryNotificationObjectKey;

/// Posted on the main thread after a repository saves a new object.
extern NSString *const ZENObjectRepositoryObjectAddedNotification;

/// Posted on the main thread after a repository saves a change to an object.
extern NSString *const ZENObjectRepositoryObjectUpdatedNotification;

/// Posted on the main thread after a repository deletes an object.
extern NSString *const ZENObjectRepositoryObjectDeletedNotification;

NS_ASSUME_NONNULL_END
