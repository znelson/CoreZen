//
//  Database.m
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"
#import "Database+Private.h"
#import "ResultSet+Private.h"
#import "Log.h"

#import <sqlite3.h>

@import FMDB;

@interface ZENDatabase () {
	// Why the open transaction must roll back, once something has decided it must
	NSError *_rollbackError;
}
@property (nonatomic, strong, readonly) FMDatabase *fmDatabase;
@end

NSErrorDomain const ZENDatabaseErrorDomain = @"ZENDatabaseErrorDomain";

NSError *ZENDatabaseErrorMake(ZENDatabaseErrorCode code, NSString *description) {
	return [NSError errorWithDomain:ZENDatabaseErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey: description }];
}

@implementation ZENDatabase

+ (instancetype)databaseWithFMDatabase:(FMDatabase *)fmDatabase {
	ZENDatabase *db = [[ZENDatabase alloc] init];
	if (db) {
		db->_fmDatabase = fmDatabase;
	}
	return db;
}

- (void)close {
	[self.fmDatabase close];
}

#pragma mark - Updates

- (BOOL)executeUpdate:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);
	BOOL result = [self.fmDatabase executeUpdate:sql withVAList:args];
	va_end(args);
	if (!result) {
		[self statementFailed:sql];
	}
	return result;
}

- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	BOOL result = [self.fmDatabase executeUpdate:sql withArgumentsInArray:arguments];
	if (!result) {
		[self statementFailed:sql];
	}
	return result;
}

#pragma mark - Queries

- (ZENResultSet *)wrapResultSet:(FMResultSet *)rs sql:(NSString *)sql {
	if (!rs) {
		[self statementFailed:sql];
		return nil;
	}
	return [ZENResultSet resultSetWithFMResultSet:rs database:self];
}

- (ZENResultSet *)executeQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);
	FMResultSet *rs = [self.fmDatabase executeQuery:sql withVAList:args];
	va_end(args);
	return [self wrapResultSet:rs sql:sql];
}

- (ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	return [self wrapResultSet:[self.fmDatabase executeQuery:sql withArgumentsInArray:arguments] sql:sql];
}

#pragma mark - Transactions

- (void)cancelTransaction {
	if (!self.inTransaction) {
		os_log(ZENLogDatabase(), "cancelTransaction was called outside a transaction, so it did nothing");
		return;
	}
	if (!_rollbackError) {
		_rollbackError = ZENDatabaseErrorMake(ZENDatabaseErrorTransactionCanceled, @"The transaction was canceled");
	}
}

- (BOOL)inTransaction {
	// FMDB's isInTransaction only changes when its own commit or rollback
	// succeeds, but SQLite can end a transaction itself when a commit fails
	sqlite3 *handle = self.fmDatabase.sqliteHandle;
	return handle && !sqlite3_get_autocommit(handle);
}

- (NSError *)rollbackError {
	return _rollbackError;
}

- (void)statementFailed:(NSString *)sql {
	// FMDB's own logging of this is off, so the message goes under CoreZen's
	// subsystem. The statement's values are bound separately, so it holds only SQL.
	os_log_error(ZENLogDatabase(), "A statement failed: %{public}@\n%{public}@", self.fmDatabase.lastErrorMessage, sql);

	// Outside a transaction a failed statement has nothing to undo
	if (!_rollbackError && self.inTransaction) {
		NSString *description = [NSString stringWithFormat:@"A statement failed: %@", self.fmDatabase.lastErrorMessage];
		_rollbackError = ZENDatabaseErrorMake(ZENDatabaseErrorStatementFailed, description);
	}
}

#pragma mark - Error

- (NSString *)lastErrorMessage {
	return [self.fmDatabase lastErrorMessage];
}

#pragma mark - Private

- (BOOL)beginTransaction {
	_rollbackError = nil;
	return [self.fmDatabase beginTransaction];
}

- (BOOL)commit {
	BOOL committed = [self.fmDatabase commit];
	if (!self.inTransaction) {
		_rollbackError = nil;
	}
	return committed;
}

- (BOOL)rollback {
	BOOL rolledBack = [self.fmDatabase rollback];
	if (!self.inTransaction) {
		_rollbackError = nil;
	}
	return rolledBack;
}

- (void)setShouldCacheStatements:(BOOL)value {
	[self.fmDatabase setShouldCacheStatements:value];
}

- (void)setTraceExecution:(BOOL)value {
	[self.fmDatabase setTraceExecution:value];
}

@end
