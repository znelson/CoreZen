//
//  Database+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"

@class FMDatabase;

// An error in ZENDatabaseErrorDomain with description as its localized description
NSError *ZENDatabaseErrorMake(ZENDatabaseErrorCode code, NSString *description);

@interface ZENDatabase (Private)

+ (instancetype)databaseWithFMDatabase:(FMDatabase *)fmDatabase;

// Closes the connection, and any result sets still open on it. Statements after
// this fail. Deallocating also closes it.
- (void)close;

// Whoever begins a transaction ends it: with commit, unless rollbackError says
// it must roll back instead. Each returns whether SQLite accepted it.
- (BOOL)beginTransaction;
- (BOOL)commit;
- (BOOL)rollback;

// Whether a transaction is open, as SQLite sees it
- (BOOL)inTransaction;

// Why the open transaction must roll back instead of committing (a statement in
// it failed, or a block canceled it), or nil if it can commit
- (NSError *)rollbackError;

// Logs a failed statement, and records it, so the open transaction rolls back.
// ZENResultSet calls it when stepping through rows fails.
- (void)statementFailed:(NSString *)sql;

- (void)setShouldCacheStatements:(BOOL)value;
- (void)setTraceExecution:(BOOL)value;

@end
