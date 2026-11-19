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

	ZENSetLargestObjectIdentifier(counter);
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
