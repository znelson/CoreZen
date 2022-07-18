//
//  ObjectIdentifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

void CZNSetLargestObjectIdentifier(CZNIdentifier inIdentifier);

CZNIdentifier CZNGetNextObjectIdentifier(void);

NS_ASSUME_NONNULL_END
