//
//  Identifiable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol CZNIdentifiable

@property (nonatomic, readonly) CZNIdentifier identifier;

@end

NS_ASSUME_NONNULL_END
