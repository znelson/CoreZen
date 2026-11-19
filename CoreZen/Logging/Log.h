//
//  Log.h
//  CoreZen
//

#import <Foundation/Foundation.h>
#import <os/log.h>

NS_ASSUME_NONNULL_BEGIN

// CoreZen logs to the unified log, under the subsystem com.zdnelson.CoreZen,
// with a category for each part of the framework. An app's developer can then
// show or hide them in Console, or stream them with:
//
//   log stream --predicate 'subsystem == "com.zdnelson.CoreZen"'
//
// Levels:
// - error: something failed, such as a write that wasn't saved
// - default: worth noticing but harmless, such as a method called twice
// - info: routine, such as a database opening
// The unified log keeps info messages only in memory unless asked to keep them.
//
// Text that can name the user's files, like a path, a URL or a message from mpv,
// is logged as private, which the unified log hides unless the Mac is set to
// show private data. Text CoreZen or SQLite writes, like an SQL statement or an
// error message, is public.

// ZENDatabaseQueue, ZENDatabase and ZENDatabaseSchema
os_log_t ZENLogDatabase(void);

// Repositories and domain objects
os_log_t ZENLogDomain(void);

// Media files, and the frames rendered from them
os_log_t ZENLogMedia(void);

// The media player, and mpv
os_log_t ZENLogPlayer(void);

// Everything else
os_log_t ZENLogGeneral(void);

NS_ASSUME_NONNULL_END
