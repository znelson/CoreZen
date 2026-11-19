//
//  DomainCallbacks.h
//  CoreZen
//
//  Created by Zach Nelson on 7/4/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifier.h>

NS_ASSUME_NONNULL_BEGIN

// Block to return control after async work completes
typedef void (^ZENAsyncContinueBlock)(void);

// Block to return control after async work completes, with NSError result
typedef void (^ZENAsyncCompletionBlock)(NSError *_Nullable error);

// Block to return control after fetching results data
typedef void (^ZENFetchResultsBlock)(NSArray *fetchedObjects);

// Block to return control after fetching an object count
typedef void (^ZENAsyncCountCompletionBlock)(NSUInteger count);

NS_ASSUME_NONNULL_END
