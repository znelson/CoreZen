//
//  DomainCallbacks.h
//  CoreZen
//
//  Created by Zach Nelson on 7/4/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifier.h>

NS_ASSUME_NONNULL_BEGIN

/// A block called when asynchronous work finishes.
typedef void (^ZENAsyncContinueBlock)(void);

/// A block called when asynchronous work finishes, with nil if it succeeded, or
/// else the error.
typedef void (^ZENAsyncCompletionBlock)(NSError *_Nullable error);

/// A block called with the objects a fetch found.
///
/// A fetch whose query fails calls it with no objects.
typedef void (^ZENFetchResultsBlock)(NSArray *fetchedObjects);

/// A block called with a count, or a sum.
typedef void (^ZENAsyncCountCompletionBlock)(NSUInteger count);

NS_ASSUME_NONNULL_END
