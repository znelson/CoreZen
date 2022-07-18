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

@protocol ZENDomainObject<NSObject, ZENIdentifiable>

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

// Allows object to perform async initialization. Called from thread pool.
- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncContinueBlock)completion;

@end

@interface ZENDomainObject : NSObject<ZENDomainObject>

@property (nonatomic, strong, readonly) ZENDataTransferObject *basicDTO;

- (instancetype)initWithDTO:(ZENDataTransferObject *)dto;

- (void)performAsyncInit:(id<ZENDataModel>)model
			  completion:(ZENAsyncContinueBlock)completion;

// Calls performAsyncInit on a thread pool for each of the objects,
// then completion block after, also on thread pool.
+ (void)asyncInit:(NSArray *)objects
			model:(id<ZENDataModel>)model
	   completion:(ZENAsyncContinueBlock)completion;

#pragma mark - ZENIdentifier protocol

- (ZENIdentifier)identifier;

@end
