//
//  DataTransferObject.h
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import <CoreZen/Identifiable.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// A DTO's values are the properties its subclass declares. Copying one copies
// them all, so a copy can be changed without changing the original, and its
// values put back with takeValuesFromDTO:.
@interface ZENDataTransferObject : NSObject <ZENIdentifiable, NSCopying>

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier;

// Sets every property the subclass declares to dto's value for it. dto must be
// of the same class. Read-only properties are left alone, like the identifier.
- (void)takeValuesFromDTO:(ZENDataTransferObject *)dto;

@end

NS_ASSUME_NONNULL_END
