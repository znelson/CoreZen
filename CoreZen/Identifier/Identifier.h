//
//  Identifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <stdint.h>

/// A 64-bit integer that identifies a stored object.
///
/// Identifiers come from ``ZENGetNextObjectIdentifier``, so each is unique across
/// every table in every database the process opens.
typedef int64_t ZENIdentifier;

/// The value for no identifier.
static const ZENIdentifier ZENInvalidIdentifier = -1;
