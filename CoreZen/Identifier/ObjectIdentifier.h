//
//  ObjectIdentifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

// Identifiers come from one counter for the whole process, shared by every table,
// so each is unique across every database the process opens.

// Hands out the next identifier
ZENIdentifier ZENGetNextObjectIdentifier(void);

// Moves the counter past identifier, which something already uses, unless it's
// past it already. It never moves the counter back, so a process can call it for
// each database it opens. ZENDatabaseSchema does, with its largest identifier.
void ZENRaiseLargestObjectIdentifier(ZENIdentifier identifier);

// Sets the counter so the next identifier is identifier + 1, even if that moves
// it back to identifiers already handed out. For tests that want predictable
// identifiers; everything else should raise the counter instead.
void ZENSetLargestObjectIdentifier(ZENIdentifier identifier);
