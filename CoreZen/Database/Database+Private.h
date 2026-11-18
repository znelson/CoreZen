//
//  Database+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"

@class FMDatabase;

@interface ZENDatabase (Private)

+ (instancetype)databaseWithFMDatabase:(FMDatabase *)fmDatabase;

// Whoever begins a transaction ends it: with commit, unless rollbackReason says
// it must roll back instead. Each returns whether SQLite accepted it.
- (BOOL)beginTransaction;
- (BOOL)commit;
- (BOOL)rollback;

// Whether a transaction is open, as SQLite sees it
- (BOOL)inTransaction;

// Why the open transaction must roll back instead of committing (a statement in
// it failed, or a block canceled it), or nil if it can commit
- (NSString *)rollbackReason;

// Records a failed statement, which the open transaction must roll back for.
// ZENResultSet calls it when stepping through rows fails.
- (void)statementFailed;

- (void)setShouldCacheStatements:(BOOL)value;
- (void)setTraceExecution:(BOOL)value;

@end
