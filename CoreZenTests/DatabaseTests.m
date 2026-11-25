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
#import "TestLog.h"
#import "DatabaseQueue+Private.h"

#import <fcntl.h>
#import <libproc.h>

// How many file descriptors this process has open on the file at URL. Each
// SQLite connection to a database file holds one.
static NSUInteger ZENOpenDescriptorCount(NSURL *URL) {
	char target[PATH_MAX];
	if (!realpath(URL.fileSystemRepresentation, target)) {
		return 0;
	}
	int size = proc_pidinfo(getpid(), PROC_PIDLISTFDS, 0, NULL, 0);
	if (size <= 0) {
		return 0;
	}
	struct proc_fdinfo *descriptors = malloc(size);
	size = proc_pidinfo(getpid(), PROC_PIDLISTFDS, 0, descriptors, size);
	NSUInteger count = 0;
	for (int i = 0; i < size / (int)PROC_PIDLISTFD_SIZE; i++) {
		char path[MAXPATHLEN];
		if (descriptors[i].proc_fdtype == PROX_FDTYPE_VNODE &&
			fcntl(descriptors[i].proc_fd, F_GETPATH, path) == 0 &&
			strcmp(path, target) == 0) {
			count++;
		}
	}
	free(descriptors);
	return count;
}

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
		XCTAssertTrue([schema initializeDatabase:database error:NULL]);
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

// Initializes the queue's database with a schema of one table, either on its
// own or inside a transaction, and returns what initializeDatabase:error: did
- (BOOL)initializeTableClass:(Class)tableClass
					 onQueue:(ZENDatabaseQueue *)queue
			   inTransaction:(BOOL)inTransaction
					   error:(NSError **)outError {
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[tableClass]];
	__block BOOL initialized = NO;
	__block NSError *error = nil;
	ZENDatabaseBlock initialize = ^(ZENDatabase *database) {
		initialized = [schema initializeDatabase:database error:&error];
	};
	if (inTransaction) {
		[queue transactionSync:initialize];
	} else {
		[queue fetchSync:initialize];
	}
	if (outError) {
		*outError = error;
	}
	return initialized;
}

- (BOOL)tableExists:(NSString *)tableName onQueue:(ZENDatabaseQueue *)queue {
	__block BOOL exists = NO;
	[queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:@"SELECT name FROM sqlite_master WHERE type='table' AND name=?;", tableName];
		exists = [rs next];
		[rs close];
	}];
	return exists;
}

- (void)testSchemaUpdateReportsSuccess {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	NSError *error = nil;
	XCTAssertTrue([self initializeTableClass:[ZENTestTable class] onQueue:queue inTransaction:NO error:&error]);
	XCTAssertNil(error);
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:queue], @"1");
	[queue shutdown];
}

- (void)testSchemaUpdateAtLatestVersionReportsSuccess {
	// setUp already brought the queue's database to the latest version, so this
	// update has nothing to do
	NSError *error = nil;
	XCTAssertTrue([self initializeTableClass:[ZENTestTable class] onQueue:self.queue inTransaction:NO error:&error]);
	XCTAssertNil(error);
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:self.queue], @"1");
}

// Version 2 of the broken migration fails after version 1 made its table
- (void)checkFailedSchemaUpdateInTransaction:(BOOL)inTransaction {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	NSError *error = nil;
	XCTAssertFalse([self initializeTableClass:[ZENBrokenMigrationTestTable class]
									  onQueue:queue
								inTransaction:inTransaction
										error:&error]);
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorStatementFailed);
	XCTAssertTrue([error.localizedDescription containsString:@"no such table: no_such_table"],
				  @"The error should have SQLite's message: %@", error.localizedDescription);

	// Rolling back the whole update leaves the database at version 0, so the
	// update runs again next time instead of skipping the broken migration
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:queue], @"0");
	XCTAssertFalse([self tableExists:@"broken_migration_objects" onQueue:queue],
				   @"Version 1's table should roll back with the failed version 2");
	[queue shutdown];
}

- (void)testFailedSchemaUpdateRollsBackAndReportsTheStatement {
	[self checkFailedSchemaUpdateInTransaction:NO];
}

- (void)testFailedSchemaUpdateInsideTransactionRollsBackAndReportsTheStatement {
	[self checkFailedSchemaUpdateInTransaction:YES];
}

- (void)testSchemaUpdateInsideCanceledTransactionFails {
	// The update would work, but it joins a transaction that's set to roll back
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENTestTable class]]];
	__block BOOL initialized = YES;
	__block NSError *error = nil;
	[queue transactionSync:^(ZENDatabase *database) {
		[database cancelTransaction];
		initialized = [schema initializeDatabase:database error:&error];
	}];
	XCTAssertFalse(initialized);
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorTransactionCanceled);
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:queue], @"0");
	[queue shutdown];
}

- (void)testFailedSchemaCommitRollsBackAndReportsTheCommit {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemoryWithOptions:ZENDatabaseQueueOptionForeignKeys];
	NSError *error = nil;
	XCTAssertFalse([self initializeTableClass:[ZENUncommittableMigrationTestTable class]
									  onQueue:queue
								inTransaction:NO
										error:&error]);
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);
	XCTAssertTrue([error.localizedDescription containsString:@"FOREIGN KEY constraint failed"],
				  @"The error should have SQLite's message: %@", error.localizedDescription);
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:queue], @"0");
	XCTAssertFalse([self tableExists:@"uncommittable_migration_objects" onQueue:queue]);
	[queue shutdown];
}

- (void)testFailedSchemaCommitDoesNotHoldTheNextTransaction {
	// A failed commit can leave its transaction open. The next transaction would
	// then run inside it, and roll back with it.
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemoryWithOptions:ZENDatabaseQueueOptionForeignKeys];
	[self initializeTableClass:[ZENUncommittableMigrationTestTable class] onQueue:queue inTransaction:NO error:NULL];
	[queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE later (value INTEGER);"]);
	}];
	XCTAssertTrue([self tableExists:@"later" onQueue:queue], @"The next transaction should commit on its own");
	[queue shutdown];
}

- (void)testFailedSchemaUpdateStillRaisesIdentifiers {
	// A database from an earlier version has rows, though its update fails, as an
	// app's might when its newest migration doesn't fit the database. New objects
	// mustn't reuse the rows' identifiers.
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE broken_migration_objects (identifier INTEGER PRIMARY KEY, name TEXT);"]);
		XCTAssertTrue([database executeUpdate:@"INSERT INTO broken_migration_objects VALUES (100, 'row');"]);
	}];
	XCTAssertFalse([self initializeTableClass:[ZENBrokenMigrationTestTable class] onQueue:queue inTransaction:NO error:NULL]);
	XCTAssertEqual(ZENGetNextObjectIdentifier(), 101);
	[queue shutdown];
}

- (void)testDeprecatedInitializeDatabaseStillUpdates {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseQueue *brokenQueue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENTestTable class]]];
	ZENDatabaseSchema *brokenSchema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENBrokenMigrationTestTable class]]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	[queue fetchSync:^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	}];
	// It has no error to give back when the update fails
	[brokenQueue fetchSync:^(ZENDatabase *database) {
		[brokenSchema initializeDatabase:database];
	}];
#pragma clang diagnostic pop
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:queue], @"1");
	XCTAssertEqualObjects([self valueOfPragma:@"user_version" onQueue:brokenQueue], @"0");
	[queue shutdown];
	[brokenQueue shutdown];
}

#pragma mark - Identifiers

// Fills a fresh database with rows, then simulates an app relaunch: the global
// identifier counter is reset and the schema initializes the database again.
- (void)relaunchWithIdentifiers:(NSArray<NSArray<NSNumber *> *> *)identifiers
					   inTables:(NSArray<Class> *)tableClasses {
	[self openWithIdentifiers:identifiers inTables:tableClasses counterAt:0];
}

// Like relaunchWithIdentifiers:inTables:, but with the counter at counter when
// the schema initializes the database, as if other work in the process had
// already handed out identifiers up to counter
- (void)openWithIdentifiers:(NSArray<NSArray<NSNumber *> *> *)identifiers
				   inTables:(NSArray<Class> *)tableClasses
				  counterAt:(ZENIdentifier)counter {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:tableClasses];
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertTrue([schema initializeDatabase:database error:NULL]);
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

	ZENSetLargestObjectIdentifier(counter);
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertTrue([schema initializeDatabase:database error:NULL]);
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

- (void)testOpeningDatabaseWithSmallerIdentifiersKeepsCounter {
	// Another database open in the process has handed out identifiers up to 500.
	// Opening one whose largest is 100 mustn't send the counter back, or new
	// objects would get identifiers the other database already uses.
	[self openWithIdentifiers:@[@[@99, @100], @[]]
					 inTables:@[[ZENTestTable class], [ZENOtherTestTable class]]
					counterAt:500];
	XCTAssertEqual(ZENGetNextObjectIdentifier(), 501);
}

- (void)testOpeningDatabaseWithLargerIdentifiersRaisesCounter {
	[self openWithIdentifiers:@[@[@99, @100], @[]]
					 inTables:@[[ZENTestTable class], [ZENOtherTestTable class]]
					counterAt:50];
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

- (void)testTransactionRollsBackWhenCommitFails {
	// SQLite checks a deferred foreign key only at COMMIT, so the statements below
	// succeed and the commit fails
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"PRAGMA foreign_keys = ON;"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE parents (identifier INTEGER PRIMARY KEY);"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE orphans "
											  @"(parent INTEGER REFERENCES parents (identifier) DEFERRABLE INITIALLY DEFERRED);"]);
	}];
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertTrue([database executeUpdate:@"INSERT INTO orphans VALUES (-1);"]);
	}];
	XCTAssertEqual([self countRows], 0u, @"The failed commit should roll back the insert");

	// The rollback ended the transaction, so the next one commits on its own
	[self.queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Beta" database:database]);
	}];
	XCTAssertEqual([self countRows], 1u);
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

#pragma mark - Transaction Results

// Runs updateBlock in an async transaction on queue, and returns the error its
// result block got
- (NSError *)resultOfTransaction:(ZENDatabaseBlock)updateBlock onQueue:(ZENDatabaseQueue *)queue {
	XCTestExpectation *finished = [self expectationWithDescription:@"transaction result"];
	__block NSError *result = nil;
	[queue transactionAsync:updateBlock
					 result:^(NSError *error) {
						 result = error;
						 [finished fulfill];
					 }];
	[self waitForExpectations:@[finished] timeout:5.0];
	return result;
}

- (void)testTransactionResultIsNilOnceCommitted {
	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
	}
									   onQueue:self.queue];
	XCTAssertNil(error);
	XCTAssertEqual([self countRows], 1u);
}

- (void)testTransactionResultReportsAFailedStatement {
	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertFalse([database executeUpdate:@"INSERT INTO no_such_table VALUES (1);"]);
	}
									   onQueue:self.queue];
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorStatementFailed);
	XCTAssertEqual([self countRows], 0u);
}

- (void)testTransactionResultReportsACancel {
	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		[database cancelTransaction];
	}
									   onQueue:self.queue];
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorTransactionCanceled);
	XCTAssertEqual([self countRows], 0u);
}

- (void)testTransactionResultReportsAFailedCommit {
	// SQLite checks a deferred foreign key only at COMMIT, so the statements below
	// succeed and the commit fails
	[self.queue fetchSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"PRAGMA foreign_keys = ON;"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE parents (identifier INTEGER PRIMARY KEY);"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE orphans "
											  @"(parent INTEGER REFERENCES parents (identifier) DEFERRABLE INITIALLY DEFERRED);"]);
	}];
	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
		XCTAssertTrue([database executeUpdate:@"INSERT INTO orphans VALUES (-1);"]);
	}
									   onQueue:self.queue];
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);
	XCTAssertEqual([self countRows], 0u);
}

- (void)testTransactionResultReportsADatabaseThatIsNotOpen {
	// No database can be made in a folder that doesn't exist
	NSURL *URL = [[self temporaryDatabaseURL].URLByDeletingLastPathComponent URLByAppendingPathComponent:@"Missing/Test.db"];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	__block BOOL blockRan = NO;
	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		// The block still runs, without a database, so it can finish what it started
		XCTAssertNil(database);
		blockRan = YES;
	}
									   onQueue:queue];
	[queue shutdown];
	XCTAssertTrue(blockRan);
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorNotOpen);
}

- (void)testTransactionResultComesBeforeLaterWork {
	// Both run on the queue, so they don't need a lock
	NSMutableArray<NSString *> *order = [NSMutableArray array];
	XCTestExpectation *fetched = [self expectationWithDescription:@"fetched"];
	[self.queue transactionAsync:^(ZENDatabase *database) {
		[order addObject:@"transaction"];
	}
		result:^(NSError *error) {
			[order addObject:@"result"];
		}];
	[self.queue fetchAsync:^(ZENDatabase *database) {
		[order addObject:@"fetch"];
		[fetched fulfill];
	}];
	[self waitForExpectations:@[fetched] timeout:5.0];
	XCTAssertEqualObjects(order, (@[@"transaction", @"result", @"fetch"]));
}

- (void)testTransactionResultBlockMayBeNil {
	[self.queue transactionAsync:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
	}
						  result:nil];
	XCTAssertEqual([self countRows], 1u);
}

#pragma mark - Connection

- (NSURL *)temporaryDatabaseURL {
	NSFileManager *fileManager = NSFileManager.defaultManager;
	NSURL *directory = [fileManager.temporaryDirectory URLByAppendingPathComponent:NSUUID.UUID.UUIDString
																	   isDirectory:YES];
	XCTAssertTrue([fileManager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:nil]);
	[self addTeardownBlock:^{
		[fileManager removeItemAtURL:directory error:nil];
	}];
	return [directory URLByAppendingPathComponent:@"test.db"];
}

// Rows in the table, or -1 if the query fails, as it does when there's no such table
- (NSInteger)countRowsInTable:(NSString *)tableName database:(ZENDatabase *)database {
	NSString *statement = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@;", tableName];
	ZENResultSet *rs = [database executeQuery:statement];
	NSInteger count = [rs next] ? [rs longLongIntForColumnIndex:0] : -1;
	[rs close];
	return count;
}

// Runs blocks on the queue from the main thread, from a background thread, and
// asynchronously, so GCD runs them on more than one thread. Each block finds the
// temporary table the first one made: temporary tables belong to a connection,
// so they're only there if every block used the same one.
- (void)useQueueFromSeveralThreads:(ZENDatabaseQueue *)queue {
	[queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TEMP TABLE scratch (value INTEGER);"]);
		XCTAssertTrue([database executeUpdate:@"INSERT INTO scratch VALUES (1);"]);
	}];

	XCTestExpectation *fetchedAsync = [self expectationWithDescription:@"async fetch"];
	[queue fetchAsync:^(ZENDatabase *database) {
		XCTAssertEqual([self countRowsInTable:@"scratch" database:database], 1, @"Async block used another connection");
		[fetchedAsync fulfill];
	}];

	// Hold the queue weakly here, so this block can't keep it alive after it finishes
	XCTestExpectation *fetchedInBackground = [self expectationWithDescription:@"background fetch"];
	__weak ZENDatabaseQueue *weakQueue = queue;
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		@autoreleasepool {
			[weakQueue fetchSync:^(ZENDatabase *database) {
				XCTAssertEqual([self countRowsInTable:@"scratch" database:database], 1,
							   @"Background thread's block used another connection");
			}];
		}
		[fetchedInBackground fulfill];
	});
	[self waitForExpectations:@[fetchedAsync, fetchedInBackground] timeout:5.0];

	// Runs after the async block has finished and been released
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertEqual([self countRowsInTable:@"scratch" database:database], 1, @"Main thread's block used another connection");
	}];
}

- (void)testBlocksShareOneConnection {
	[self useQueueFromSeveralThreads:self.queue];
}

- (void)testQueueOpensOneConnection {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[self useQueueFromSeveralThreads:queue];
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 1u);
	[queue shutdown];
}

- (void)testShutdownClosesTheDatabase {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[self useQueueFromSeveralThreads:queue];
	[queue shutdown];
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 0u);
}

- (void)testReleasingTheQueueClosesTheDatabase {
	NSURL *URL = [self temporaryDatabaseURL];
	__weak ZENDatabaseQueue *weakQueue = nil;
	@autoreleasepool {
		ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
		weakQueue = queue;
		[self useQueueFromSeveralThreads:queue];
	}
	XCTAssertNil(weakQueue, @"Nothing should keep the queue alive once its blocks have finished");
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 0u);
}

- (void)testShutdownBlockRunsBeforeTheDatabaseCloses {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE saved (value INTEGER);"]);
	}];
	[queue shutdown:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"INSERT INTO saved VALUES (1);"]);
	}];
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 0u);

	ZENDatabaseQueue *reopened = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[reopened fetchSync:^(ZENDatabase *database) {
		XCTAssertEqual([self countRowsInTable:@"saved" database:database], 1);
	}];
	[reopened shutdown];
}

- (void)testBlocksAfterShutdownDoNotRun {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertNotNil(database);
	}];
	[queue shutdown];

	__block BOOL ran = NO;
	[queue transactionSync:^(ZENDatabase *database) {
		ran = YES;
	}];
	[queue fetchSync:^(ZENDatabase *database) {
		ran = YES;
	}];
	[queue fetchAsync:^(ZENDatabase *database) {
		ran = YES;
	}];
	[queue transactionAsync:^(ZENDatabase *database) {
		ran = YES;
	}];
	[queue vacuumAsync];
	XCTAssertFalse(ran);
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 0u, @"Nothing should reopen the database after shutdown");
}

- (void)testSecondShutdownDoesNotRunItsBlock {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	__block NSUInteger shutdownBlocks = 0;
	[queue shutdown:^(ZENDatabase *database) {
		XCTAssertNotNil(database);
		shutdownBlocks++;
	}];
	[queue shutdown:^(ZENDatabase *database) {
		shutdownBlocks++;
	}];
	XCTAssertEqual(shutdownBlocks, 1u, @"The database is closed by the time a second shutdown asks for it");
	XCTAssertEqual(ZENOpenDescriptorCount(URL), 0u);
}

- (void)testInMemoryQueuesHaveSeparateDatabases {
	ZENDatabaseQueue *other = [ZENDatabaseQueue databaseQueueInMemory];
	[other fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:@"SELECT COUNT(*) FROM sqlite_master WHERE name = 'test_objects';"];
		XCTAssertTrue([rs next]);
		XCTAssertEqual([rs longLongIntForColumnIndex:0], 0, @"setUp made test_objects in the other queue's database only");
		[rs close];
	}];
	[other shutdown];
}

#pragma mark - Shutdown

// Shuts the queue down while the work queueWork queues is still waiting its turn:
// an earlier block holds the queue until shutdown has started.
- (void)shutdownQueue:(ZENDatabaseQueue *)queue
		 afterQueuing:(void (^)(void))queueWork
		shutdownBlock:(ZENDatabaseBlock)shutdownBlock {
	dispatch_semaphore_t holding = dispatch_semaphore_create(0);
	[queue fetchAsync:^(ZENDatabase *database) {
		dispatch_semaphore_signal(holding);
		// Shutdown turns on its work queue's terminate token, then waits for this
		// block. The work queue is private, so this reads the token by key path.
		NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:5.0];
		while (![[queue valueForKeyPath:@"workQueue.terminateToken.terminated"] boolValue] &&
			   deadline.timeIntervalSinceNow > 0) {
			usleep(1000);
		}
	}];
	XCTAssertEqual(dispatch_semaphore_wait(holding, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);
	queueWork();
	[queue shutdown:shutdownBlock];
}

- (void)testShutdownRunsWorkQueuedBeforeIt {
	ZENDatabaseQueue *queue = self.queue;
	self.queue = nil; // So tearDown doesn't shut it down again

	__block BOOL fetched = NO;
	__block NSInteger rowsAtShutdown = -1;
	[self shutdownQueue:queue
		afterQueuing:^{
			[queue transactionAsync:^(ZENDatabase *database) {
				XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
			}];
			[queue fetchAsync:^(ZENDatabase *database) {
				fetched = YES;
			}];
		}
		shutdownBlock:^(ZENDatabase *database) {
			rowsAtShutdown = [self countRowsInTable:@"test_objects" database:database];
		}];

	XCTAssertTrue(fetched, @"A fetch queued before shutdown should run");
	XCTAssertEqual(rowsAtShutdown, 1, @"A transaction queued before shutdown should commit before shutdown's block runs");
}

- (void)testShutdownWithoutBlockRunsWorkQueuedBeforeIt {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[queue transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE saved (value INTEGER);"]);
	}];
	[self shutdownQueue:queue
		   afterQueuing:^{
			   [queue transactionAsync:^(ZENDatabase *database) {
				   XCTAssertTrue([database executeUpdate:@"INSERT INTO saved VALUES (1);"]);
			   }];
		   }
		  shutdownBlock:nil];

	ZENDatabaseQueue *reopened = [ZENDatabaseQueue databaseQueueWithURL:URL];
	[reopened fetchSync:^(ZENDatabase *database) {
		XCTAssertEqual([self countRowsInTable:@"saved" database:database], 1,
					   @"A transaction queued before shutdown should be saved");
	}];
	[reopened shutdown];
}

#pragma mark - Write-Ahead Log

// The value a pragma reports on the queue's connection
- (NSString *)valueOfPragma:(NSString *)pragma onQueue:(ZENDatabaseQueue *)queue {
	__block NSString *value = nil;
	[queue fetchSync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:[NSString stringWithFormat:@"PRAGMA %@;", pragma]];
		value = [rs next] ? [rs stringForColumnIndex:0] : nil;
		[rs close];
	}];
	return value;
}

- (void)testDatabaseFileUsesWriteAheadLog {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:[self temporaryDatabaseURL]];
	XCTAssertEqualObjects([self valueOfPragma:@"journal_mode" onQueue:queue], @"wal");
	XCTAssertEqualObjects([self valueOfPragma:@"synchronous" onQueue:queue], @"1", @"synchronous should be NORMAL");
	[queue shutdown];
}

- (void)testWriteSavesWhileAnotherConnectionReads {
	NSURL *URL = [self temporaryDatabaseURL];
	ZENDatabaseQueue *writer = [ZENDatabaseQueue databaseQueueWithURL:URL];
	ZENDatabaseQueue *reader = [ZENDatabaseQueue databaseQueueWithURL:URL];
	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENTestTable class]]];
	[writer transactionSync:^(ZENDatabase *database) {
		XCTAssertTrue([schema initializeDatabase:database error:NULL]);
		XCTAssertTrue([self insertRowNamed:@"Alpha" database:database]);
	}];

	// The reader stops partway through a query, which keeps its read going, until
	// the writer has finished
	dispatch_semaphore_t reading = dispatch_semaphore_create(0);
	dispatch_semaphore_t written = dispatch_semaphore_create(0);
	XCTestExpectation *readFinished = [self expectationWithDescription:@"read finished"];
	[reader fetchAsync:^(ZENDatabase *database) {
		ZENResultSet *rs = [database executeQuery:@"SELECT name FROM test_objects;"];
		XCTAssertTrue([rs next]);
		dispatch_semaphore_signal(reading);
		dispatch_semaphore_wait(written, dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC));
		// A read sees the database as it was when the read began
		XCTAssertFalse([rs next]);
		[rs close];
		[readFinished fulfill];
	}];
	XCTAssertEqual(dispatch_semaphore_wait(reading, dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC)), 0);

	NSError *error = [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([self insertRowNamed:@"Beta" database:database]);
	}
									   onQueue:writer];
	dispatch_semaphore_signal(written);
	[self waitForExpectations:@[readFinished] timeout:5.0];
	XCTAssertNil(error, @"The write should save while the other connection reads");

	// The reader's next read sees it
	[reader fetchSync:^(ZENDatabase *database) {
		XCTAssertEqual([self countRowsInTable:@"test_objects" database:database], 2);
	}];
	[writer shutdown];
	[reader shutdown];
}

- (void)testInMemoryDatabaseKeepsItsJournal {
	// An in-memory database can't have a write-ahead log, and doesn't need one
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	XCTAssertEqualObjects([self valueOfPragma:@"journal_mode" onQueue:queue], @"memory");
	[queue shutdown];
}

#pragma mark - Foreign Keys

// Makes a table whose rows refer to rows of another, and adds one that refers to
// a row that isn't there, all in the queue's first transaction. Returns its result.
- (NSError *)addRowWithMissingReferenceOnQueue:(ZENDatabaseQueue *)queue {
	return [self resultOfTransaction:^(ZENDatabase *database) {
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE parents (identifier INTEGER PRIMARY KEY);"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE children (parent INTEGER REFERENCES parents (identifier));"]);
		[database executeUpdate:@"INSERT INTO children VALUES (1);"];
	}
							 onQueue:queue];
}

- (void)testForeignKeysAreEnforcedWhenAskedFor {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemoryWithOptions:ZENDatabaseQueueOptionForeignKeys];
	NSError *error = [self addRowWithMissingReferenceOnQueue:queue];
	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorStatementFailed);
	XCTAssertTrue([error.localizedDescription containsString:@"FOREIGN KEY constraint failed"], @"%@", error);
	[queue shutdown];
}

- (void)testForeignKeysAreEnforcedInADatabaseFile {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:[self temporaryDatabaseURL]
															 options:ZENDatabaseQueueOptionForeignKeys];
	XCTAssertEqual([self addRowWithMissingReferenceOnQueue:queue].code, ZENDatabaseErrorStatementFailed);
	[queue shutdown];
}

- (void)testForeignKeysAreNotEnforcedByDefault {
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueInMemory];
	XCTAssertNil([self addRowWithMissingReferenceOnQueue:queue]);
	[queue shutdown];
}

#pragma mark - Logging

- (void)testDatabaseLogsUnderCoreZensSubsystem {
	NSString *marker = ZENLogMarker();
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:[self temporaryDatabaseURL]];
	[queue fetchSync:^(ZENDatabase *database) {
		XCTAssertNil([database executeQuery:@"SELECT name FROM no_such_table;"]);
	}];
	[queue shutdown];
	NSArray<OSLogEntryLog *> *entries = ZENLogEntriesAfter(marker);

	// Something routine is info, and a failure is an error, with the SQL that failed
	XCTAssertEqual(ZENCoreZenLogEntries(entries, @"Database", OSLogEntryLogLevelInfo, @"Opening the database at").count, 1u);
	NSString *failure = @"A statement failed: no such table: no_such_table\nSELECT name FROM no_such_table;";
	XCTAssertEqual(ZENCoreZenLogEntries(entries, @"Database", OSLogEntryLogLevelError, failure).count, 1u);

	// FMDB doesn't log the failure a second time
	NSPredicate *fmdbErrors = [NSPredicate predicateWithFormat:@"composedMessage BEGINSWITH 'DB Error'"];
	XCTAssertEqual([entries filteredArrayUsingPredicate:fmdbErrors].count, 0u);
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
