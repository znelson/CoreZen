//
//  ObjectIdentifier+Private.h
//  CoreZen
//

#import "ObjectIdentifier.h"

// Moves the counter past identifier, which something already uses, unless it's
// past it already. It never moves the counter back, so a process can call it for
// each database it opens. ZENDatabaseSchema does, with its largest identifier.
void ZENRaiseLargestObjectIdentifier(ZENIdentifier identifier);
