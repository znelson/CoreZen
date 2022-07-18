//
//  ObjectIdentifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

void ZENSetLargestObjectIdentifier(ZENIdentifier inIdentifier);

ZENIdentifier ZENGetNextObjectIdentifier(void);
