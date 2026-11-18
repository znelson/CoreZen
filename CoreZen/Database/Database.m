//
//  Database.m
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"
#import "Database+Private.h"
#import "ResultSet+Private.h"

#import <sqlite3.h>

@import FMDB;

@interface ZENDatabase () {
	// Why the open transaction must roll back, once something has decided it must
	NSString *_rollbackReason;
}
@property (nonatomic, strong, readonly) FMDatabase *fmDatabase;
@end

@implementation ZENDatabase

+ (instancetype)databaseWithFMDatabase:(FMDatabase *)fmDatabase {
	ZENDatabase *db = [[ZENDatabase alloc] init];
	if (db) {
		db->_fmDatabase = fmDatabase;
	}
	return db;
}

#pragma mark - Updates

- (BOOL)executeUpdate:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);
	BOOL result = [self.fmDatabase executeUpdate:sql withVAList:args];
	va_end(args);
	if (!result) {
		[self statementFailed];
	}
	return result;
}

- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	BOOL result = [self.fmDatabase executeUpdate:sql withArgumentsInArray:arguments];
	if (!result) {
		[self statementFailed];
	}
	return result;
}

#pragma mark - Queries

- (ZENResultSet *)wrapResultSet:(FMResultSet *)rs {
	if (!rs) {
		[self statementFailed];
		return nil;
	}
	return [ZENResultSet resultSetWithFMResultSet:rs database:self];
}

- (ZENResultSet *)executeQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);
	FMResultSet *rs = [self.fmDatabase executeQuery:sql withVAList:args];
	va_end(args);
	return [self wrapResultSet:rs];
}

- (ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	return [self wrapResultSet:[self.fmDatabase executeQuery:sql withArgumentsInArray:arguments]];
}

#pragma mark - Transactions

- (void)cancelTransaction {
	if (!self.inTransaction) {
		NSLog(@"WARNING: cancelTransaction called outside a transaction");
		return;
	}
	if (!_rollbackReason) {
		_rollbackReason = @"the transaction was canceled";
	}
}

- (BOOL)inTransaction {
	// FMDB's isInTransaction only changes when its own commit or rollback
	// succeeds, but SQLite can end a transaction itself when a commit fails
	sqlite3 *handle = self.fmDatabase.sqliteHandle;
	return handle && !sqlite3_get_autocommit(handle);
}

- (NSString *)rollbackReason {
	return _rollbackReason;
}

- (void)statementFailed {
	// Outside a transaction a failed statement has nothing to undo
	if (!_rollbackReason && self.inTransaction) {
		_rollbackReason = [NSString stringWithFormat:@"a statement failed: %@", self.fmDatabase.lastErrorMessage];
	}
}

#pragma mark - Error

- (NSString *)lastErrorMessage {
	return [self.fmDatabase lastErrorMessage];
}

#pragma mark - Private

- (BOOL)beginTransaction {
	_rollbackReason = nil;
	return [self.fmDatabase beginTransaction];
}

- (BOOL)commit {
	BOOL committed = [self.fmDatabase commit];
	if (!self.inTransaction) {
		_rollbackReason = nil;
	}
	return committed;
}

- (BOOL)rollback {
	BOOL rolledBack = [self.fmDatabase rollback];
	if (!self.inTransaction) {
		_rollbackReason = nil;
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
