//
//  Log.m
//  CoreZen
//

#import "Log.h"

static const char *const kZENLogSubsystem = "com.zdnelson.CoreZen";

// Each category's log is made once, on first use, and kept
#define ZEN_LOG_CATEGORY(function, category)                 \
	os_log_t function(void) {                                \
		static os_log_t log;                                 \
		static dispatch_once_t once;                         \
		dispatch_once(&once, ^{                              \
			log = os_log_create(kZENLogSubsystem, category); \
		});                                                  \
		return log;                                          \
	}

ZEN_LOG_CATEGORY(ZENLogDatabase, "Database")
ZEN_LOG_CATEGORY(ZENLogDomain, "Domain")
ZEN_LOG_CATEGORY(ZENLogMedia, "Media")
ZEN_LOG_CATEGORY(ZENLogPlayer, "Player")
ZEN_LOG_CATEGORY(ZENLogGeneral, "General")
