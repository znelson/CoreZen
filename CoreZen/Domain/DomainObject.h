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

/// The object a repository passes to the async init of each of its objects.
///
/// It's usually the app's model, so an object can find the objects it relates
/// to. The protocol has no requirements.
@protocol ZENDataModel
@end

/// The methods a repository needs from the objects it makes from its table's
/// rows.
///
/// A repository's objects are usually subclasses of ``ZENDomainObject-c.class``,
/// which conforms to it.
@protocol ZENDomainObject <NSObject, ZENIdentifiable>

/// Makes an object from a row's DTO.
- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

/// Finishes setting up the object, asynchronously, after it's made.
///
/// A repository calls this on a background thread, once, when it first makes
/// the object from the database, and delivers the object to fetches only after
/// it completes. Call completion with nil when initialization succeeds, or with
/// an error when it fails. A repository leaves an object whose init failed out
/// of fetch results and drops it from its cache, and
/// ``ZENObjectRepository/asyncInitAndAdd:completion:`` doesn't add it.
- (void)performAsyncInit:(nullable id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

@end

/// An object built around a DTO, which holds its stored values.
///
/// Subclass it for each kind of object a repository stores. A subclass adds what
/// the app needs beyond the stored values, and can override
/// ``performAsyncInit:completion:`` to finish setting itself up, such as by
/// checking a file on disk, reading media metadata or fetching related objects.
@interface ZENDomainObject : NSObject <ZENDomainObject>

/// The DTO with the object's stored values.
///
/// It's nil only in a subclass that starts without one and sets it later.
@property (nonatomic, strong, readonly, nullable) ZENDataTransferObject *basicDTO;

/// Makes an object around a DTO, which becomes its ``basicDTO``.
- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

/// Finishes setting up the object, asynchronously, after it's made.
///
/// By default it calls completion with nil right away. A subclass that has more
/// to do overrides it, and calls completion with nil when it's done, or with an
/// error if it fails.
- (void)performAsyncInit:(nullable id<ZENDataModel>)model
			  completion:(ZENAsyncCompletionBlock)completion;

/// Called once a repository has saved a change to the object's DTO.
///
/// It's called after an update in a write batch has put its values in, or after
/// ``ZENObjectRepository/updateObject:completion:`` has saved the object. An
/// object that keeps state worked out from its DTO brings it up to date here.
/// It runs on the database queue, before observers are told about the change, so
/// it should be quick. It does nothing by default.
- (void)didUpdateDTO;

/// Runs the async init of several objects at once.
///
/// It calls each object's ``performAsyncInit:completion:`` on a background
/// thread, then calls completion on a background thread once they've all
/// finished. Only the first call to each object's completion counts; later
/// calls are ignored. Completion gets nil if every object's init succeeded, or
/// else one of the errors the objects reported.
+ (void)asyncInit:(NSArray *)objects
			model:(nullable id<ZENDataModel>)model
	   completion:(nullable ZENAsyncCompletionBlock)completion;

#pragma mark - ZENIdentifier protocol

/// The identifier of the object's ``basicDTO``.
- (ZENIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
