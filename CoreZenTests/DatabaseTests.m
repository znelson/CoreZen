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

// The schema version and whether the broken migration's table exists, after
// initializing a fresh database with it, either on its own or inside a transaction
- (void)initializeBrokenMigrationInTransaction:(BOOL)inTransaction
								 schemaVersion:(long long *)schemaVersion
								   tableExists:(BOOL *)tableExists {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENBrokenMigrationTestTable class]]];
	ZENDatabaseBlock initialize = ^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	};
	if (inTransaction) {
		[queue transactionSync:initialize];
	} else {
		[queue fetchSync:initialize];
	}
	[queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:@"PRAGMA user_version;"];
		XCTAssertTrue([rs next]);
		*schemaVersion = [rs longLongIntForColumnIndex:0];
		[rs close];
		rs = [database executeQuery:@"SELECT name FROM sqlite_master WHERE type='table' AND name='broken_migration_objects';"];
		*tableExists = [rs next];
		[rs close];
	}];
	[queue shutdown];
}

- (void)testFailedSchemaUpdateRollsBack {
	// Rolling back the whole update leaves the database at version 0, so the
	// update runs again next time instead of skipping the broken migration
	long long schemaVersion = -1;
	BOOL tableExists = YES;
	[self initializeBrokenMigrationInTransaction:NO schemaVersion:&schemaVersion tableExists:&tableExists];
	XCTAssertEqual(schemaVersion, 0);
	XCTAssertFalse(tableExists, @"Version 1's table should roll back with the failed version 2");
}

- (void)testFailedSchemaUpdateInsideTransactionRollsBack {
	long long schemaVersion = -1;
	BOOL tableExists = YES;
	[self initializeBrokenMigrationInTransaction:YES schemaVersion:&schemaVersion tableExists:&tableExists];
	XCTAssertEqual(schemaVersion, 0);
	XCTAssertFalse(tableExists, @"Version 1's table should roll back with the failed version 2");
}

#pragma mark - Identifiers

// Fills a fresh database with rows, then simulates an app relaunch: the global
// identifier counter is reset and the schema initializes the database again.
- (void)relaunchWithIdentifiers:(NSArray<NSArray<NSNumber *> *> *)identifiers
					   inTables:(NSArray<Class> *)tableClasses {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:tableClasses];
	[queue fetchSync:^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	}];
	[queue transactionSync:^(ZENDatabase *database) {
		[tableClasses enumerateObjectsUsingBlock:^(Class tableClass, NSUInteger index, BOOL *stop) {
			ZENTestTable *table = [tableClass new];
			for (NSNumber *identifier in identifiers[index]) {
				ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:identifier.longLongValue name:@"row"];
				XCTAssertTrue([table insertDTO:dto database:database]);
			}
		}];
	}];

	ZENSetLargestObjectIdentifier(0);
	[queue fetchSync:^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	}];
	[queue shutdown];
}

- (void)testIdentifiersResumeAfterLargestInEarlierTable {
	// Identifiers come from one global counter shared by every table. The last
	// table holds the smaller identifiers here, so it must not decide the counter.
	[self relaunchWithIdentifiers:@[@[@99, @100], @[@50]]
						 inTables:@[[ZENTestTable class], [ZENOtherTestTable class]]];
	XCTAssertEqual(ZENGetNextObjectIdentifier(), 101);
}

- (void)testIdentifiersResumeAfterLargestInLastTable {
	[self relaunchWithIdentifiers:@[@[@50], @[@99, @100]]
						 inTables:@[[ZENTestTable class], [ZENOtherTestTable class]]];
	XCTAssertEqual(ZENGetNextObjectIdentifier(), 101);
}

- (void)testIdentifiersUnchangedWhenTablesAreEmpty {
	[self relaunchWithIdentifiers:@[@[], @[]]
						 inTables:@[[ZENTestTable class], [ZENOtherTestTable class]]];
	XCTAssertEqual(ZENGetNextObjectIdentifier(), 1);
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

#pragma mark - Transactions

- (NSUInteger)countRows {
	__block NSUInteger count = 0;
	[self.queue fetchSync:^(ZENDatabase *database) {
		count = [[ZENTestTable new] countAllRows:database];
	}];
	return count;
}

- (BOOL)insertRowNamed:(NSString *)name database:(ZENDatabase *)database {
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:name];
	return [[ZENTestTable new] insertDTO:dto database:database];
}

- (void)testTransactionRollsBackWhenAStatementFails {
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertFalse([database executeUpdate:@"INSERT INTO no_such_table VALUES (1);"]);
	}];
	XCTAssertEqual([self countRows], 0u, @"The insert before the failed statement should roll back");
}

- (void)testTransactionRollsBackWhenAQueryFails {
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertNil([database executeQuery:@"SELECT * FROM no_such_table;"]);
	}];
	XCTAssertEqual([self countRows], 0u, @"The insert before the failed query should roll back");
}

- (void)testAsyncTransactionRollsBackWhenAStatementFails {
	[self.queue transactionAsync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertFalse([database executeUpdate:@"INSERT INTO no_such_table VALUES (1);"]);
	}];
	XCTAssertEqual([self countRows], 0u, @"The insert before the failed statement should roll back");
}

- (void)testCanceledTransactionRollsBack {
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		[database cancelTransaction];
		// Statements after the cancel still run, and roll back too
		XCTAssertTrue([self insertRowNamed:@"Beta" database:database]);
	}];
	XCTAssertEqual([self countRows], 0u);
}

- (void)testTransactionAfterRollbackCommits {
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		[database cancelTransaction];
	}];
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Beta" database:database]);
	}];
	XCTAssertEqual([self countRows], 1u, @"Only the second transaction's insert should commit");
}

- (void)testCancelOutsideTransactionDoesNothing {
	[self.queue fetchSync:^(ZENDatabase *database) {
		[database cancelTransaction];
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
	}];
	XCTAssertEqual([self countRows], 1u, @"Outside a transaction each statement commits on its own");
}

- (void)testFailureOutsideTransactionDoesNotAffectNextTransaction {
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertFalse([database executeUpdate:@"INSERT INTO no_such_table VALUES (1);"]);
	}];
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
	}];
	XCTAssertEqual([self countRows], 1u);
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

#pragma mark - Trace Execution

// ZENDatabase keeps its FMDatabase private, so these read FMDB's setting by key path

- (void)testTraceExecutionIsOffByDefault {
	XCTAssertFalse(self.queue.traceExecution);
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertEqualObjects([database valueForKeyPath:@"fmDatabase.traceExecution"], @NO);
	}];
}

- (void)testTraceExecutionCanBeTurnedOnAndOff {
	// setUp already ran a block on the queue, so this also covers a database it created earlier
	self.queue.traceExecution = YES;
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertEqualObjects([database valueForKeyPath:@"fmDatabase.traceExecution"], @YES);
	}];

	self.queue.traceExecution = NO;
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertEqualObjects([database valueForKeyPath:@"fmDatabase.traceExecution"], @NO);
	}];
}

@end
