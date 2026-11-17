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
@class ZENDatabaseQueue;

typedef enum : NSUInteger {
	ZENObjectRepositoryCacheType_Weak = 0,
	ZENObjectRepositoryCacheType_Strong = 1
} ZENObjectRepositoryCacheType;

@interface ZENObjectRepository : NSObject

#pragma mark - Init

- (instancetype)initWithDataModel:(id<ZENDataModel>)dataModel
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

#pragma mark - Add

// Runs asynchronously. Completion block happens on a thread pool.
- (void)addObject:(ZENDomainObject *)domainObject
	   completion:(ZENAsyncContinueBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)addObject:(ZENDomainObject *)domainObject
	 uiCompletion:(ZENAsyncContinueBlock)completion;

// Helper method to call DomainObject +asyncInit: on object before
// adding to repository. If the object's async init fails, it isn't added, and
// completion gets the error. Completion block happens on a thread pool.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
			 completion:(ZENAsyncCompletionBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)asyncInitAndAdd:(ZENDomainObject *)domainObject
		   uiCompletion:(ZENAsyncCompletionBlock)completion;

#pragma mark - Update

// Runs asynchronously. Completion block happens on a thread pool.
- (void)updateObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncContinueBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)updateObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncContinueBlock)completion;

#pragma mark - Delete

// Runs asynchronously. Completion block happens on a thread pool.
- (void)deleteObject:(ZENDomainObject *)domainObject
		  completion:(ZENAsyncContinueBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void)deleteObject:(ZENDomainObject *)domainObject
		uiCompletion:(ZENAsyncContinueBlock)completion;

#pragma mark - Notifications

// Notifications are delivered on the main thread
- (void)zen_addObserver:(id)observer
			   selector:(SEL)selector;

- (void)zen_removeObserver:(id)observer;

@end


extern NSString *const ZENObjectRepositoryNotificationObjectKey;

extern NSString *const ZENObjectRepositoryObjectAddedNotification;
extern NSString *const ZENObjectRepositoryObjectUpdatedNotification;
extern NSString *const ZENObjectRepositoryObjectDeletedNotification;
