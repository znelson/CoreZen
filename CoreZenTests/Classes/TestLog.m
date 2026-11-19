//
//  TestLog.m
//  CoreZenTests
//

#import "TestLog.h"

#import <os/log.h>

NSString *ZENLogMarker(void) {
	static os_log_t log;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		log = os_log_create("com.zdnelson.CoreZenTests", "Marker");
	});
	NSString *marker = [NSString stringWithFormat:@"Marker %@", NSUUID.UUID.UUIDString];
	os_log(log, "%{public}@", marker);
	return marker;
}

// A test finds its entries by a marker instead of by the time it started,
// because the unified log keeps time differently from NSDate. It dates entries
// from the system's monotonic clock, converted to the time of day, while NSDate
// reads the time of day itself, which the system speeds up or slows down to
// correct it. An entry logged just after [NSDate date] could then be dated a few
// milliseconds before it. The log's own order doesn't depend on that.
NSArray<OSLogEntryLog *> *ZENLogEntriesAfter(NSString *marker) {
	NSError *error = nil;
	OSLogStore *store = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:&error];
	OSLogEnumerator *entries = [store entriesEnumeratorWithOptions:0 position:nil predicate:nil error:&error];
	if (!entries) {
		NSLog(@"Couldn't read this process's log: %@", error);
		return @[];
	}
	// Stays nil until the marker
	NSMutableArray<OSLogEntryLog *> *logEntries = nil;
	for (OSLogEntry *entry in entries) {
		if (![entry isKindOfClass:[OSLogEntryLog class]]) {
			continue;
		}
		OSLogEntryLog *logEntry = (OSLogEntryLog *)entry;
		if (logEntries) {
			[logEntries addObject:logEntry];
		} else if ([logEntry.composedMessage isEqualToString:marker]) {
			logEntries = [NSMutableArray array];
		}
	}
	if (!logEntries) {
		NSLog(@"Couldn't find \"%@\" in this process's log", marker);
		return @[];
	}
	return logEntries;
}

NSArray<OSLogEntryLog *> *ZENCoreZenLogEntries(NSArray<OSLogEntryLog *> *entries,
											   NSString *category,
											   OSLogEntryLogLevel level,
											   NSString *text) {
	NSIndexSet *matches = [entries indexesOfObjectsPassingTest:^BOOL(OSLogEntryLog *entry, NSUInteger index, BOOL *stop) {
		return [entry.subsystem isEqualToString:@"com.zdnelson.CoreZen"] && [entry.category isEqualToString:category] &&
			   entry.level == level && [entry.composedMessage containsString:text];
	}];
	return [entries objectsAtIndexes:matches];
}
