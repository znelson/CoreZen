//
//  Identifiable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

/// An object with an identifier.
@protocol ZENIdentifiable

/// The object's identifier.
@property (nonatomic, readonly) ZENIdentifier identifier;

@end
