//
//  Identifiable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

@protocol ZENIdentifiable

@property (nonatomic, readonly) ZENIdentifier identifier;

@end
