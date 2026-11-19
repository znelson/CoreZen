//
//  TestLog.h
//  CoreZenTests
//

#import <Foundation/Foundation.h>

@import OSLog;

NS_ASSUME_NONNULL_BEGIN

// Logs a message that no other entry has, and returns it. A test calls this
// before what it checks, then reads the entries after it with ZENLogEntriesAfter.
NSString *ZENLogMarker(void);

// Everything this process logged after marker, oldest first, CoreZen's messages
// and others'. Reading the log takes a second or two, so a test reads it once.
NSArray<OSLogEntryLog *> *ZENLogEntriesAfter(NSString *marker);

// The entries CoreZen logged in category, at level, whose message contains text
NSArray<OSLogEntryLog *> *ZENCoreZenLogEntries(NSArray<OSLogEntryLog *> *entries,
											   NSString *category,
											   OSLogEntryLogLevel level,
											   NSString *text);

NS_ASSUME_NONNULL_END
