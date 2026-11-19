//
//  TestLog.m
//  CoreZenTests
//

#import "TestLog.h"

NSArray<OSLogEntryLog *> *ZENLogEntriesSince(NSDate *date) {
	NSError *error = nil;
	OSLogStore *store = [OSLogStore storeWithScope:OSLogStoreCurrentProcessIdentifier error:&error];
	if (!store) {
		NSLog(@"Couldn't open this process's log: %@", error);
		return @[];
	}
	OSLogEnumerator *entries = [store entriesEnumeratorWithOptions:0
														  position:[store positionWithDate:date]
														 predicate:nil
															 error:&error];
	NSMutableArray<OSLogEntryLog *> *logEntries = [NSMutableArray array];
	for (OSLogEntry *entry in entries) {
		// The position is approximate, so it can start a little early
		if ([entry isKindOfClass:[OSLogEntryLog class]] && [entry.date compare:date] != NSOrderedAscending) {
			[logEntries addObject:(OSLogEntryLog *)entry];
		}
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
