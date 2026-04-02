//
//  DatabaseTests.m
//  CoreZenTests
//
//  Created by Zach Nelson on 7/18/22.
//

#import <XCTest/XCTest.h>

@import CoreZen;

#import "TestDTO.h"
#import "TestTable.h"

@interface DatabaseTests : XCTestCase

@property (nonatomic, strong) ZENDatabaseQueue *queue;

@end

@implementation DatabaseTests

- (void)setUp {
	ZENSetLargestObjectIdentifier(0);
	self.queue = [ZENDatabaseQueue databaseQueueInMemory];
	XCTAssertNotNil(self.queue);

	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENTestTable class]]];
	[self.queue transactionSync:^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	}];
}

- (void)tearDown {
	[self.queue shutdown];
	self.queue = nil;
}

#pragma mark - Schema

- (void)testSchemaCreatesTable {
	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:
			@"SELECT name FROM sqlite_master WHERE type='table' AND name='test_objects';"];
		XCTAssertTrue([rs next], @"test_objects table should exist");
		XCTAssertEqualObjects([rs stringForColumnIndex:0], @"test_objects");
		[rs close];
	}];
}

- (void)testSchemaVersionIsSet {
	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:@"PRAGMA user_version;"];
		XCTAssertTrue([rs next]);
		long long version = [rs longLongIntForColumnIndex:0];
		XCTAssertEqual(version, 1, @"Schema version should be 1 after first migration");
		[rs close];
	}];
}

#pragma mark - Insert

- (void)testInsertAndFetchDTO {
	ZENTestTable *table = [ZENTestTable new];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Alice"];

	[self.queue transactionSync:^(ZENDatabase *database) {
		BOOL result = [table insertDTO:dto database:database];
		XCTAssertTrue(result, @"Insert should succeed");
	}];

	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [table rowByIdentifier:id1 database:database];
		XCTAssertTrue([rs next], @"Should find the inserted row");
		ZENTestDTO *fetched = (ZENTestDTO *)[table dtoFromRow:rs];
		XCTAssertEqual(fetched.identifier, id1);
		XCTAssertEqualObjects(fetched.name, @"Alice");
		[rs close];
	}];
}

#pragma mark - Update

- (void)testUpdateDTO {
	ZENTestTable *table = [ZENTestTable new];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Bob"];

	[self.queue transactionSync:^(ZENDatabase *database) {
		[table insertDTO:dto database:database];
	}];

	dto.name = @"Robert";
	[self.queue transactionSync:^(ZENDatabase *database) {
		BOOL result = [table updateDTO:dto database:database];
		XCTAssertTrue(result, @"Update should succeed");
	}];

	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [table rowByIdentifier:id1 database:database];
		XCTAssertTrue([rs next]);
		ZENTestDTO *fetched = (ZENTestDTO *)[table dtoFromRow:rs];
		XCTAssertEqualObjects(fetched.name, @"Robert");
		[rs close];
	}];
}

#pragma mark - Delete

- (void)testDeleteByIdentifier {
	ZENTestTable *table = [ZENTestTable new];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Charlie"];

	[self.queue transactionSync:^(ZENDatabase *database) {
		[table insertDTO:dto database:database];
	}];

	[self.queue transactionSync:^(ZENDatabase *database) {
		BOOL result = [table deleteByIdentifier:id1 database:database];
		XCTAssertTrue(result, @"Delete should succeed");
	}];

	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [table rowByIdentifier:id1 database:database];
		XCTAssertFalse([rs next], @"Deleted row should not be found");
		[rs close];
	}];
}

#pragma mark - Count

- (void)testCountAllRows {
	ZENTestTable *table = [ZENTestTable new];

	[self.queue transactionSync:^(ZENDatabase *database) {
		for (int i = 0; i < 5; i++) {
			ZENIdentifier ident = ZENGetNextObjectIdentifier();
			NSString *name = [NSString stringWithFormat:@"Item %d", i];
			ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ident name:name];
			[table insertDTO:dto database:database];
		}
	}];

	[self.queue fetchSync:^(ZENDatabase *database) {
		NSUInteger count = [table countAllRows:database];
		XCTAssertEqual(count, 5u, @"Should have 5 rows");
	}];
}

#pragma mark - All Rows

- (void)testAllRowsReturnsAllInsertedObjects {
	ZENTestTable *table = [ZENTestTable new];
	NSArray *names = @[@"X", @"Y", @"Z"];

	[self.queue transactionSync:^(ZENDatabase *database) {
		for (NSString *name in names) {
			ZENIdentifier ident = ZENGetNextObjectIdentifier();
			ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ident name:name];
			[table insertDTO:dto database:database];
		}
	}];

	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [table allRows:database];
		NSMutableArray *fetchedNames = [NSMutableArray new];
		while ([rs next]) {
			ZENTestDTO *dto = (ZENTestDTO *)[table dtoFromRow:rs];
			[fetchedNames addObject:dto.name];
		}
		[rs close];
		XCTAssertEqualObjects(fetchedNames, names,
							  @"Should fetch all inserted names in order");
	}];
}

#pragma mark - Async Operations

- (void)testTransactionAsync {
	XCTestExpectation *expectation = [self expectationWithDescription:@"async transaction"];
	ZENTestTable *table = [ZENTestTable new];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Async"];

	[self.queue transactionAsync:^(ZENDatabase *database) {
		[table insertDTO:dto database:database];
	}];

	[self.queue fetchAsync:^(ZENDatabase *database) {
		NSUInteger count = [table countAllRows:database];
		XCTAssertEqual(count, 1u);
		[expectation fulfill];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
