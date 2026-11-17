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
		[database executeUpdate:
		 @"CREATE TABLE IF NOT EXISTS test_objects ("
		 "identifier INTEGER PRIMARY KEY, "
		 "name TEXT"
		 ");"];
		return YES;
	}
	return NO;
}

- (BOOL)insertDTO:(ZENDataTransferObject *)dto database:(ZENDatabase *)database {
	ZENTestDTO *testDTO = (ZENTestDTO *)dto;
	return [database executeUpdate:@"INSERT INTO test_objects (identifier, name) VALUES (?, ?);"
			  withArgumentsInArray:@[@(testDTO.identifier), testDTO.name ?: [NSNull null]]];
}

- (BOOL)updateDTO:(ZENDataTransferObject *)dto database:(ZENDatabase *)database {
	ZENTestDTO *testDTO = (ZENTestDTO *)dto;
	return [database executeUpdate:@"UPDATE test_objects SET name = ? WHERE identifier = ?;"
			  withArgumentsInArray:@[testDTO.name ?: [NSNull null], @(testDTO.identifier)]];
}

- (BOOL)deleteByIdentifier:(ZENIdentifier)identifier database:(ZENDatabase *)database {
	return [database executeUpdate:@"DELETE FROM test_objects WHERE identifier = ?;"
			  withArgumentsInArray:@[@(identifier)]];
}

- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row {
	ZENIdentifier identifier = [row longLongIntForColumnIndex:0];
	NSString *name = [row stringForColumnIndex:1];
	return [[ZENTestDTO alloc] initWithIdentifier:identifier name:name];
}

- (ZENResultSet *)allRows:(ZENDatabase *)database {
	return [database executeQuery:@"SELECT identifier, name FROM test_objects ORDER BY identifier;"];
}

- (ZENResultSet *)rowByIdentifier:(ZENIdentifier)identifier database:(ZENDatabase *)database {
	return [database executeQuery:@"SELECT identifier, name FROM test_objects WHERE identifier = ?;"
			 withArgumentsInArray:@[@(identifier)]];
}

- (NSUInteger)countAllRows:(ZENDatabase *)database {
	ZENResultSet *rs = [database executeQuery:@"SELECT COUNT(*) FROM test_objects;"];
	NSUInteger count = 0;
	if ([rs next]) {
		count = (NSUInteger)[rs longLongIntForColumnIndex:0];
	}
	[rs close];
	return count;
}

@end
