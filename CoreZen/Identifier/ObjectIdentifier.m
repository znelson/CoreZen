//
//  ObjectIdentifier.m
//  CoreZen
//
//  Created by Zach Nelson on 3/27/19.
//

#import "ObjectIdentifier+Private.h"

#import <stdatomic.h>

// By starting at identifier 1 and incrementing we eliminate half of the possible range of values. But positive
// numbers are nicer to work from and we should never need the full 64-bit range. I want to leave this as a
// signed 64-bit integer, instead of switching to unsigned, because SQLite3 uses signed 64-bit integers.
static atomic_int_fast64_t nextIdentifier = 1;

void ZENRaiseLargestObjectIdentifier(ZENIdentifier identifier) {
	// Other threads may hand out or raise identifiers meanwhile. A failed exchange
	// reloads next, so this retries until the counter is past identifier, by this
	// change or another thread's.
	int_fast64_t next = atomic_load(&nextIdentifier);
	while (next <= identifier && !atomic_compare_exchange_weak(&nextIdentifier, &next, identifier + 1)) {
	}
}

void ZENSetLargestObjectIdentifier(ZENIdentifier identifier) {
	atomic_store(&nextIdentifier, identifier + 1);
}

ZENIdentifier ZENGetNextObjectIdentifier(void) {
	return atomic_fetch_add(&nextIdentifier, 1);
}
