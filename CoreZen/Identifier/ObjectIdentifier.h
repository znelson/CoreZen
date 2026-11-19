//
//  ObjectIdentifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

// Identifiers come from one counter for the whole process, shared by every table,
// so each is unique across every database the process opens. ZENDatabaseSchema
// moves the counter past the largest identifier in each database it initializes,
// and never moves it back.

// Hands out the next identifier
ZENIdentifier ZENGetNextObjectIdentifier(void);

// Sets the counter so the next identifier is identifier + 1, even if that moves
// it back to identifiers already handed out. For tests that want predictable
// identifiers; everything else should raise the counter instead.
void ZENSetLargestObjectIdentifier(ZENIdentifier identifier);
