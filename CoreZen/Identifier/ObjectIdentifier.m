//
//  ObjectIdentifier.m
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import "ObjectIdentifier.h"

#import <stdatomic.h>

// By starting at identifier 1 and incrementing we eliminate half of the possible range of values. But positive
// numbers are nicer to work from and we should never need the full 64-bit range. I want to leave this as a
// signed 64-bit integer, instead of switching to unsigned, because SQLite3 uses signed 64-bit integers.
static atomic_int_fast64_t nextIdentifier = 1;

void ZENSetLargestObjectIdentifier(ZENIdentifier identifier) {
	atomic_store(&nextIdentifier, identifier+1);
}

ZENIdentifier ZENGetNextObjectIdentifier(void) {
	return atomic_fetch_add(&nextIdentifier, 1);
}
