//
//  DataTransferObject.h
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import <CoreZen/Identifiable.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// One row's values, in the properties a subclass declares.
///
/// A table class reads rows into data transfer objects (DTOs), and writes DTOs
/// back. Copying a DTO gives a new one with the same property values, which can
/// be changed without changing the original, and put back with
/// ``takeValuesFromDTO:``. Values that are objects are shared, not copied.
@interface ZENDataTransferObject : NSObject <ZENIdentifiable, NSCopying>

/// Makes a DTO with an identifier: a row's, or a new one from
/// ``ZENGetNextObjectIdentifier``.
- (instancetype)initWithIdentifier:(ZENIdentifier)identifier;

/// Sets every property the subclass declares to another DTO's value for it.
///
/// The other DTO must be of the same class. Read-only properties are left alone,
/// like the identifier.
- (void)takeValuesFromDTO:(ZENDataTransferObject *)dto;

@end

NS_ASSUME_NONNULL_END
