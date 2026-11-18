//
//  TestTable.m
//  CoreZenTests
//

#import "TestTable.h"
#import "TestDTO.h"

@import CoreZen;

@implementation ZENTestTable

+ (NSString *)tableName {
	return @"test_objects";
}

+ (BOOL)updateSchema:(ZENDatabase *)database version:(NSUInteger)version {
	if (version == 1) {
		NSString *sql = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (identifier INTEGER PRIMARY KEY, name TEXT);", self.tableName];
		[database executeUpdate:sql];
		return YES;
	}
	return NO;
}

- (NSString *)tableName {
	return [self.class tableName];
}

- (BOOL)insertDTO:(ZENDataTransferObject *)dto database:(ZENDatabase *)database {
	ZENTestDTO *testDTO = (ZENTestDTO *)dto;
	NSString *sql = [NSString stringWithFormat:@"INSERT INTO %@ (identifier, name) VALUES (?, ?);", self.tableName];
	return [database executeUpdate:sql withArgumentsInArray:@[@(testDTO.identifier), testDTO.name ?: [NSNull null]]];
}

- (BOOL)updateDTO:(ZENDataTransferObject *)dto database:(ZENDatabase *)database {
	ZENTestDTO *testDTO = (ZENTestDTO *)dto;
	NSString *sql = [NSString stringWithFormat:@"UPDATE %@ SET name = ? WHERE identifier = ?;", self.tableName];
	return [database executeUpdate:sql withArgumentsInArray:@[testDTO.name ?: [NSNull null], @(testDTO.identifier)]];
}

- (BOOL)deleteByIdentifier:(ZENIdentifier)identifier database:(ZENDatabase *)database {
	NSString *sql = [NSString stringWithFormat:@"DELETE FROM %@ WHERE identifier = ?;", self.tableName];
	return [database executeUpdate:sql withArgumentsInArray:@[@(identifier)]];
}

- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row {
	ZENIdentifier identifier = [row longLongIntForColumnIndex:0];
	NSString *name = [row stringForColumnIndex:1];
	return [[ZENTestDTO alloc] initWithIdentifier:identifier name:name];
}

- (ZENResultSet *)allRows:(ZENDatabase *)database {
	NSString *sql = [NSString stringWithFormat:@"SELECT identifier, name FROM %@ ORDER BY identifier;", self.tableName];
	return [database executeQuery:sql];
}

- (ZENResultSet *)rowByIdentifier:(ZENIdentifier)identifier database:(ZENDatabase *)database {
	NSString *sql = [NSString stringWithFormat:@"SELECT identifier, name FROM %@ WHERE identifier = ?;", self.tableName];
	return [database executeQuery:sql withArgumentsInArray:@[@(identifier)]];
}

- (NSUInteger)countAllRows:(ZENDatabase *)database {
	NSString *sql = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@;", self.tableName];
	ZENResultSet *rs = [database executeQuery:sql];
	NSUInteger count = 0;
	if ([rs next]) {
		count = (NSUInteger)[rs longLongIntForColumnIndex:0];
	}
	[rs close];
	return count;
}

@end

@implementation ZENOtherTestTable

+ (NSString *)tableName {
	return @"other_test_objects";
}

@end

@implementation ZENBrokenMigrationTestTable

+ (NSString *)tableName {
	return @"broken_migration_objects";
}

+ (BOOL)updateSchema:(ZENDatabase *)database version:(NSUInteger)version {
	if (version == 2) {
		NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN extra TEXT;", self.tableName];
		[database executeUpdate:sql];
		[database executeUpdate:@"INSERT INTO no_such_table VALUES (1);"];
		return YES;
	}
	return [super updateSchema:database version:version];
}

@end
