//
//  ObjectIdentifier.h
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import <CoreZen/Identifier.h>

@import Foundation;

/// Hands out the next identifier.
///
/// Identifiers come from one counter for the whole process, shared by every
/// table, so each is unique across every database the process opens. The first
/// is 1. ``ZENDatabaseSchema`` moves the counter past the largest identifier in
/// each database it initializes, and never moves it back. Any thread can call
/// this.
ZENIdentifier ZENGetNextObjectIdentifier(void);

/// Sets the counter so the next identifier is one more than this one.
///
/// It sets the counter even if that moves it back to identifiers already handed
/// out, so it's only for tests that want predictable identifiers.
void ZENSetLargestObjectIdentifier(ZENIdentifier identifier);
