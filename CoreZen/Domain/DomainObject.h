//
//  DomainObject.h
//  CoreZen
//
//  Created by Zach Nelson on 4/19/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>
#import <CoreZen/DataTransferObject.h>
#import <CoreZen/DomainCallbacks.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ZENDataModel
@end

@protocol ZENDomainObject <NSObject, ZENIdentifiable>

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

// Allows object to perform async initialization. Called from thread pool. Call
// completion with nil when initialization succeeds, or with an error when it
// fails. A repository leaves an object whose init failed out of fetch results
// and drops it from its cache, and asyncInitAndAdd: doesn't add it.
- (void)performAsyncInit:(nullable id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

@end

@interface ZENDomainObject : NSObject <ZENDomainObject>

// nil only in a subclass that starts without one and sets it later
@property (nonatomic, strong, readonly, nullable) ZENDataTransferObject *basicDTO;

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

- (void)performAsyncInit:(nullable id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

// Calls performAsyncInit on a thread pool for each of the objects,
// then completion block after, also on thread pool. Only the first call to
// each object's performAsyncInit completion counts; later calls are ignored.
// Completion gets nil if every object's init succeeded, or else one of the
// errors the objects reported.
+ (void)asyncInit:(NSArray *)objects
			model:(nullable id<ZENDataModel>)model
	   completion:(nullable ZENAsyncCompletionBlock)completion;

#pragma mark - ZENIdentifier protocol

- (ZENIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
