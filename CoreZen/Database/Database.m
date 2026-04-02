//
//  Database.m
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"
#import "Database+Private.h"
#import "ResultSet+Private.h"

@import FMDB;

@interface ZENDatabase ()
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
	return result;
}

- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	return [self.fmDatabase executeUpdate:sql withArgumentsInArray:arguments];
}

#pragma mark - Queries

- (ZENResultSet *)executeQuery:(NSString *)sql, ... {
	va_list args;
	va_start(args, sql);
	FMResultSet *rs = [self.fmDatabase executeQuery:sql withVAList:args];
	va_end(args);
	return rs ? [ZENResultSet resultSetWithFMResultSet:rs] : nil;
}

- (ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments {
	FMResultSet *rs = [self.fmDatabase executeQuery:sql withArgumentsInArray:arguments];
	return rs ? [ZENResultSet resultSetWithFMResultSet:rs] : nil;
}

#pragma mark - Error

- (NSString *)lastErrorMessage {
	return [self.fmDatabase lastErrorMessage];
}

#pragma mark - Private

- (void)beginTransaction {
	[self.fmDatabase beginTransaction];
}

- (void)commit {
	[self.fmDatabase commit];
}

- (void)rollback {
	[self.fmDatabase rollback];
}

- (void)setShouldCacheStatements:(BOOL)value {
	[self.fmDatabase setShouldCacheStatements:value];
}

- (void)setTraceExecution:(BOOL)value {
	[self.fmDatabase setTraceExecution:value];
}

@end
