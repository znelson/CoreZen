//
//  TestLog.h
//  CoreZenTests
//

#import <Foundation/Foundation.h>

@import OSLog;

NS_ASSUME_NONNULL_BEGIN

// Everything this process has logged since date, oldest first, CoreZen's messages
// and others'. Reading the log takes a second or two, so a test reads it once.
NSArray<OSLogEntryLog *> *ZENLogEntriesSince(NSDate *date);

// The entries CoreZen logged in category, at level, whose message contains text
NSArray<OSLogEntryLog *> *ZENCoreZenLogEntries(NSArray<OSLogEntryLog *> *entries,
											   NSString *category,
											   OSLogEntryLogLevel level,
											   NSString *text);

NS_ASSUME_NONNULL_END
