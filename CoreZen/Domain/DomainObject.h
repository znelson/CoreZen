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

@protocol ZENDataModel
@end

@protocol ZENDomainObject <NSObject, ZENIdentifiable>

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

// Allows object to perform async initialization. Called from thread pool. Call
// completion with nil when initialization succeeds, or with an error when it
// fails. A repository doesn't deliver, cache, or add an object whose init failed.
- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

@end

@interface ZENDomainObject : NSObject <ZENDomainObject>

@property (nonatomic, strong, readonly) ZENDataTransferObject *basicDTO;

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

// Calls performAsyncInit on a thread pool for each of the objects,
// then completion block after, also on thread pool. Only the first call to
// each object's performAsyncInit completion counts; later calls are ignored.
// Completion gets nil if every object's init succeeded, or else one of the
// errors the objects reported.
+ (void)asyncInit:(NSArray *)objects
			model:(id<ZENDataModel>)model
	   completion:(ZENAsyncCompletionBlock)completion;

#pragma mark - ZENIdentifier protocol

- (ZENIdentifier)identifier;

@end
