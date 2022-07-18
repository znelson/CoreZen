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

// Runs asynchronously. Completion block happens on a thread pool.
- (void)sumAllVideoDuration:(ZENAsyncCountCompletionBlock)countBlock;

// Same as above, but resultsBlock happens on the main thread.
- (void)sumAllVideoDurationForUI:(ZENAsyncCountCompletionBlock)countBlock;

#pragma mark - Fetch

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
// adding to repository.
- (void) asyncInitAndAdd:(ZENDomainObject *)domainObject
			  completion:(ZENAsyncContinueBlock)completion;

// Same as above, but uiCompletion block happens on the main thread.
- (void) asyncInitAndAdd:(ZENDomainObject *)domainObject
			uiCompletion:(ZENAsyncContinueBlock)completion;

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


extern NSString *ZENObjectRepositoryNotificationObjectKey;

extern NSString *ZENObjectRepositoryObjectAddedNotification;
extern NSString *ZENObjectRepositoryObjectUpdatedNotification;
extern NSString *ZENObjectRepositoryObjectDeletedNotification;
