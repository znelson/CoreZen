//
//  DomainTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

#import "TestDTO.h"
#import "TestTable.h"
#import "TestDomainObject.h"

@interface DomainTests : XCTestCase

@property (nonatomic, strong) ZENDatabaseQueue *queue;

@end

@implementation DomainTests

- (void)setUp {
	ZENSetLargestObjectIdentifier(0);
	self.queue = [ZENDatabaseQueue databaseQueueInMemory];

	ZENDatabaseSchema *schema = [ZENDatabaseSchema schemaWithTableClasses:@[[ZENTestTable class]]];
	[self.queue transactionSync:^(ZENDatabase *database) {
		[schema initializeDatabase:database];
	}];
}

- (void)tearDown {
	[self.queue shutdown];
	self.queue = nil;
}

#pragma mark - DataTransferObject

- (void)testDTODefaultIdentifier {
	ZENDataTransferObject *dto = [[ZENDataTransferObject alloc] init];
	XCTAssertEqual(dto.identifier, ZENInvalidIdentifier);
}

- (void)testDTOWithIdentifier {
	ZENDataTransferObject *dto = [[ZENDataTransferObject alloc] initWithIdentifier:42];
	XCTAssertEqual(dto.identifier, 42);
}

- (void)testTestDTOWithName {
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:1 name:@"Test"];
	XCTAssertEqual(dto.identifier, 1);
	XCTAssertEqualObjects(dto.name, @"Test");
}

#pragma mark - DomainObject

- (void)testDomainObjectCreationFromDTO {
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:10 name:@"Hello"];
	ZENTestDomainObject *obj = [[ZENTestDomainObject alloc] initWithDTO:dto];

	XCTAssertEqual(obj.identifier, 10);
	XCTAssertEqualObjects(obj.name, @"Hello");
	XCTAssertEqual(obj.basicDTO, dto);
}

- (void)testDomainObjectIdentifierPassthrough {
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"PassThrough"];
	ZENDomainObject *obj = [[ZENDomainObject alloc] initWithDTO:dto];

	XCTAssertEqual(obj.identifier, id1);
}

#pragma mark - Repository helpers

- (ZENObjectRepository *)repositoryWithEmbryo:(Class<ZENDomainObject>)embryo {
	return [[ZENObjectRepository alloc] initWithDataModel:nil
											   tableClass:[ZENTestTable class]
											databaseQueue:self.queue
									   domainObjectEmbryo:embryo
												cacheType:ZENObjectRepositoryCacheType_Strong];
}

- (ZENObjectRepository *)repository {
	return [self repositoryWithEmbryo:[ZENTestDomainObject class]];
}

// These wait for each repository call to finish, so a test makes its next call
// afterward rather than from inside a completion block. (Clang assumes methods
// named add... keep the blocks passed to them, so a completion block passed to
// addObject: that used the repository would warn of a retain cycle.)

// Adds the object and returns the add's error, or nil once it's saved
- (NSError *)addObject:(ZENDomainObject *)object toRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *added = [self expectationWithDescription:@"add"];
	__block NSError *result = nil;
	[repo addObject:object
		 completion:^(NSError *error) {
			 result = error;
			 [added fulfill];
		 }];
	[self waitForExpectations:@[added] timeout:5.0];
	return result;
}

// Adds a new object named name, which must be saved
- (ZENTestDomainObject *)addObjectNamed:(NSString *)name toRepository:(ZENObjectRepository *)repo {
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:name];
	ZENTestDomainObject *object = [[ZENTestDomainObject alloc] initWithDTO:dto];
	XCTAssertNil([self addObject:object toRepository:repo]);
	return object;
}

- (NSError *)updateObject:(ZENDomainObject *)object inRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *updated = [self expectationWithDescription:@"update"];
	__block NSError *result = nil;
	[repo updateObject:object
			completion:^(NSError *error) {
				result = error;
				[updated fulfill];
			}];
	[self waitForExpectations:@[updated] timeout:5.0];
	return result;
}

- (NSError *)deleteObject:(ZENDomainObject *)object fromRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *deleted = [self expectationWithDescription:@"delete"];
	__block NSError *result = nil;
	[repo deleteObject:object
			completion:^(NSError *error) {
				result = error;
				[deleted fulfill];
			}];
	[self waitForExpectations:@[deleted] timeout:5.0];
	return result;
}

- (NSUInteger)countObjectsInRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *counted = [self expectationWithDescription:@"count"];
	__block NSUInteger result = 0;
	[repo countAllObjects:^(NSUInteger count) {
		result = count;
		[counted fulfill];
	}];
	[self waitForExpectations:@[counted] timeout:5.0];
	return result;
}

- (NSArray *)fetchAllFromRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *fetched = [self expectationWithDescription:@"fetch all"];
	__block NSArray *result = nil;
	[repo fetchAllObjects:^(NSArray *fetchedObjects) {
		result = fetchedObjects;
		[fetched fulfill];
	}];
	[self waitForExpectations:@[fetched] timeout:5.0];
	return result;
}

- (NSArray *)fetchObjectWithIdentifier:(ZENIdentifier)identifier fromRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *fetched = [self expectationWithDescription:@"fetch"];
	__block NSArray *result = nil;
	[repo fetchObjectByIdentifier:identifier
					   completion:^(NSArray *fetchedObjects) {
						   result = fetchedObjects;
						   [fetched fulfill];
					   }];
	[self waitForExpectations:@[fetched] timeout:5.0];
	return result;
}

// Makes every later transaction that runs statement ("INSERT", "UPDATE" or
// "DELETE") on test_objects fail when it commits, after the statement itself
// succeeded: a trigger adds a row that breaks a deferred foreign key, which
// SQLite only checks at COMMIT
- (void)failCommitsAfter:(NSString *)statement {
	[self.queue fetchSync:^(ZENDatabase *database) {
		// Foreign keys are off by default; this lasts as long as the queue's connection
		XCTAssertTrue([database executeUpdate:@"PRAGMA foreign_keys = ON;"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE IF NOT EXISTS parents (identifier INTEGER PRIMARY KEY);"]);
		XCTAssertTrue([database executeUpdate:@"CREATE TABLE IF NOT EXISTS orphans "
											  @"(parent INTEGER REFERENCES parents (identifier) DEFERRABLE INITIALLY DEFERRED);"]);
		NSString *trigger = [NSString stringWithFormat:@"CREATE TRIGGER orphan_after_%@ AFTER %@ ON test_objects "
													   @"BEGIN INSERT INTO orphans VALUES (-1); END;",
													   statement.lowercaseString, statement];
		XCTAssertTrue([database executeUpdate:trigger]);
	}];
}

// An expectation that fails if repo posts notification before it's waited on
- (XCTestExpectation *)expectNo:(NSNotificationName)notification fromRepository:(ZENObjectRepository *)repo {
	XCTestExpectation *posted = [self expectationForNotification:notification object:repo handler:nil];
	posted.inverted = YES;
	return posted;
}

#pragma mark - ObjectRepository Integration

- (void)testRepositoryAddAndFetch {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *object = [self addObjectNamed:@"RepoTest" toRepository:repo];

	XCTestExpectation *fetched = [self expectationWithDescription:@"fetch"];
	[repo fetchObjectByIdentifier:object.identifier
					   completion:^(NSArray *fetchedObjects) {
						   XCTAssertEqual(fetchedObjects.count, 1u);
						   ZENTestDomainObject *fetchedObject = fetchedObjects.firstObject;
						   XCTAssertEqual(fetchedObject.identifier, object.identifier);
						   [fetched fulfill];
					   }];
	[self waitForExpectations:@[fetched] timeout:5.0];
}

- (void)testRepositoryDeleteObject {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *object = [self addObjectNamed:@"ToDelete" toRepository:repo];

	XCTAssertNil([self deleteObject:object fromRepository:repo]);
	XCTAssertEqual([self countObjectsInRepository:repo], 0u);
}

- (void)testRepositoryCountAllObjects {
	ZENObjectRepository *repo = self.repository;
	[self addObjectNamed:@"One" toRepository:repo];
	[self addObjectNamed:@"Two" toRepository:repo];

	XCTAssertEqual([self countObjectsInRepository:repo], 2u);
}

- (void)testRepositorySumColumn {
	ZENObjectRepository *repo = self.repository;
	ZENIdentifier id1 = [self addObjectNamed:@"One" toRepository:repo].identifier;
	ZENIdentifier id2 = [self addObjectNamed:@"Two" toRepository:repo].identifier;

	XCTestExpectation *summed = [self expectationWithDescription:@"sum"];
	[repo sumColumn:@"identifier"
		 completion:^(NSUInteger sum) {
			 XCTAssertEqual(sum, (NSUInteger)(id1 + id2));
			 [summed fulfill];
		 }];
	[self waitForExpectations:@[summed] timeout:5.0];
}

- (void)testRepositorySumColumnOfEmptyTableIsZeroOnMainThread {
	XCTestExpectation *summed = [self expectationWithDescription:@"sum"];
	[self.repository sumColumn:@"identifier"
				  uiCompletion:^(NSUInteger sum) {
					  XCTAssertEqual(sum, 0u);
					  XCTAssertTrue(NSThread.isMainThread);
					  [summed fulfill];
				  }];
	[self waitForExpectations:@[summed] timeout:5.0];
}

- (void)testRepositoryFetchAllObjects {
	ZENObjectRepository *repo = self.repository;
	[self addObjectNamed:@"Alpha" toRepository:repo];
	[self addObjectNamed:@"Beta" toRepository:repo];

	XCTAssertEqual([self fetchAllFromRepository:repo].count, 2u);
}

- (void)testRepositoryUpdateObject {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *object = [self addObjectNamed:@"Original" toRepository:repo];

	// Change the name and push the update through the repository
	((ZENTestDTO *)object.basicDTO).name = @"Updated";
	XCTAssertNil([self updateObject:object inRepository:repo]);

	// Read the row straight from the database
	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENTestTable *table = [ZENTestTable new];
		ZENResultSet *rs = [table rowByIdentifier:object.identifier database:database];
		XCTAssertTrue([rs next]);
		ZENTestDTO *fetched = (ZENTestDTO *)[table dtoFromRow:rs];
		XCTAssertEqualObjects(fetched.name, @"Updated");
		[rs close];
	}];
}

#pragma mark - Failed writes

- (void)testAddWhoseCommitFailsIsNotCachedOrAnnounced {
	ZENObjectRepository *repo = self.repository;
	[self failCommitsAfter:@"INSERT"];
	XCTestExpectation *announced = [self expectNo:ZENObjectRepositoryObjectAddedNotification fromRepository:repo];

	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Doomed"];
	ZENTestDomainObject *object = [[ZENTestDomainObject alloc] initWithDTO:dto];
	NSError *error = [self addObject:object toRepository:repo];
	[self waitForExpectations:@[announced] timeout:0.5];

	XCTAssertEqualObjects(error.domain, ZENDatabaseErrorDomain);
	XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);

	XCTAssertEqual([self countObjectsInRepository:repo], 0u, @"The insert should have rolled back");
	XCTAssertEqual([self fetchObjectWithIdentifier:object.identifier fromRepository:repo].count, 0u,
				   @"An object that wasn't saved shouldn't be in the cache");
}

- (void)testUpdateWhoseCommitFailsIsNotAnnounced {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *object = [self addObjectNamed:@"Original" toRepository:repo];
	[self failCommitsAfter:@"UPDATE"];
	XCTestExpectation *announced = [self expectNo:ZENObjectRepositoryObjectUpdatedNotification fromRepository:repo];

	((ZENTestDTO *)object.basicDTO).name = @"Doomed";
	NSError *error = [self updateObject:object inRepository:repo];
	[self waitForExpectations:@[announced] timeout:0.5];

	XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);

	[self.queue fetchSync:^(ZENDatabase *database) {
		ZENTestTable *table = [ZENTestTable new];
		ZENResultSet *rs = [table rowByIdentifier:object.identifier database:database];
		XCTAssertTrue([rs next]);
		XCTAssertEqualObjects(((ZENTestDTO *)[table dtoFromRow:rs]).name, @"Original", @"The update should have rolled back");
		[rs close];
	}];
}

- (void)testDeleteWhoseCommitFailsKeepsObjectCached {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *object = [self addObjectNamed:@"Survivor" toRepository:repo];
	[self failCommitsAfter:@"DELETE"];
	XCTestExpectation *announced = [self expectNo:ZENObjectRepositoryObjectDeletedNotification fromRepository:repo];

	NSError *error = [self deleteObject:object fromRepository:repo];
	[self waitForExpectations:@[announced] timeout:0.5];

	XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);

	XCTAssertEqual([self countObjectsInRepository:repo], 1u, @"The delete should have rolled back");
	NSArray *fetched = [self fetchObjectWithIdentifier:object.identifier fromRepository:repo];
	XCTAssertEqual(fetched.firstObject, object, @"The row is still there, so its object should still be the cached one");
}

- (void)testAsyncInitAndAddReportsFailedInsert {
	ZENObjectRepository *repo = self.repository;
	ZENTestDomainObject *first = [self addObjectNamed:@"First" toRepository:repo];

	// Same identifier as first, so the insert breaks the primary key
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:first.identifier name:@"Duplicate"];
	ZENTestDomainObject *duplicate = [[ZENTestDomainObject alloc] initWithDTO:dto];
	XCTestExpectation *added = [self expectationWithDescription:@"add"];
	__block NSError *addError = nil;
	[repo asyncInitAndAdd:duplicate
			   completion:^(NSError *error) {
				   addError = error;
				   [added fulfill];
			   }];
	[self waitForExpectations:@[added] timeout:5.0];

	XCTAssertEqual(addError.code, ZENDatabaseErrorStatementFailed, @"The insert failed, so the add should report it");
	XCTAssertEqual([self fetchObjectWithIdentifier:first.identifier fromRepository:repo].firstObject, first);
}

- (void)testWriteThatTableRefusesReportsWriteFailed {
	ZENObjectRepository *repo = [[ZENObjectRepository alloc] initWithDataModel:nil
																	tableClass:[ZENRefusingTestTable class]
																 databaseQueue:self.queue
															domainObjectEmbryo:[ZENTestDomainObject class]
																	 cacheType:ZENObjectRepositoryCacheType_Strong];
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Refused"];
	ZENTestDomainObject *object = [[ZENTestDomainObject alloc] initWithDTO:dto];
	XCTestExpectation *announced = [self expectNo:ZENObjectRepositoryObjectAddedNotification fromRepository:repo];

	NSError *error = [self addObject:object toRepository:repo];
	[self waitForExpectations:@[announced] timeout:0.5];

	XCTAssertEqual(error.code, ZENDatabaseErrorWriteFailed);
	XCTAssertEqual([self updateObject:object inRepository:repo].code, ZENDatabaseErrorWriteFailed);
	XCTAssertEqual([self deleteObject:object fromRepository:repo].code, ZENDatabaseErrorWriteFailed);
	XCTAssertEqual([self fetchObjectWithIdentifier:object.identifier fromRepository:repo].count, 0u);
}

- (void)testWriteToDatabaseThatWontOpenReportsNotOpen {
	NSURL *URL = [NSURL fileURLWithPath:@"/no-such-directory/CoreZenTests.db"];
	ZENDatabaseQueue *queue = [ZENDatabaseQueue databaseQueueWithURL:URL];
	ZENObjectRepository *repo = [[ZENObjectRepository alloc] initWithDataModel:nil
																	tableClass:[ZENTestTable class]
																 databaseQueue:queue
															domainObjectEmbryo:[ZENTestDomainObject class]
																	 cacheType:ZENObjectRepositoryCacheType_Strong];
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Nowhere"];

	NSError *error = [self addObject:[[ZENTestDomainObject alloc] initWithDTO:dto] toRepository:repo];
	XCTAssertEqual(error.code, ZENDatabaseErrorNotOpen);
	[queue shutdown];
}

- (void)testFailedWriteReportsErrorOnMainThread {
	ZENObjectRepository *repo = self.repository;
	[self failCommitsAfter:@"INSERT"];
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Doomed"];

	XCTestExpectation *added = [self expectationWithDescription:@"add"];
	[repo addObject:[[ZENTestDomainObject alloc] initWithDTO:dto]
		uiCompletion:^(NSError *error) {
			XCTAssertTrue(NSThread.isMainThread);
			XCTAssertEqual(error.code, ZENDatabaseErrorCommitFailed);
			[added fulfill];
		}];
	[self waitForExpectations:@[added] timeout:5.0];
}

- (void)testSavedWriteAnnouncesItself {
	ZENObjectRepository *repo = self.repository;
	XCTestExpectation *announced = [self expectationForNotification:ZENObjectRepositoryObjectAddedNotification
															 object:repo
															handler:nil];
	ZENTestDomainObject *object = [self addObjectNamed:@"Saved" toRepository:repo];
	[self waitForExpectations:@[announced] timeout:5.0];
	XCTAssertEqual([self fetchObjectWithIdentifier:object.identifier fromRepository:repo].firstObject, object);
}

#pragma mark - Async init

// Writes rows straight to the table, so the repository first meets them on fetch
- (NSArray<NSNumber *> *)insertRowsNamed:(NSArray<NSString *> *)names {
	NSMutableArray<NSNumber *> *identifiers = [NSMutableArray new];
	ZENTestTable *table = [ZENTestTable new];
	[self.queue transactionSync:^(ZENDatabase *database) {
		for (NSString *name in names) {
			ZENIdentifier identifier = ZENGetNextObjectIdentifier();
			[table insertDTO:[[ZENTestDTO alloc] initWithIdentifier:identifier name:name] database:database];
			[identifiers addObject:@(identifier)];
		}
	}];
	return identifiers;
}

- (void)testFetchAllRunsAsyncInitOncePerObject {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENSlowInitDomainObject class]];
	[self insertRowsNamed:@[@"Alpha", @"Beta"]];

	NSArray<ZENSlowInitDomainObject *> *first = [self fetchAllFromRepository:repo];
	NSArray<ZENSlowInitDomainObject *> *second = [self fetchAllFromRepository:repo];

	XCTAssertEqual(first.count, 2u);
	XCTAssertEqualObjects(first, second, @"Second fetch should return the cached objects");
	for (ZENSlowInitDomainObject *object in second) {
		XCTAssertTrue(object.initialized);
		XCTAssertEqual(object.asyncInitCount, 1, @"Cached objects shouldn't be initialized again");
	}
}

- (void)testFetchByIdentifierRunsAsyncInitOnce {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENSlowInitDomainObject class]];
	ZENIdentifier identifier = [self insertRowsNamed:@[@"Alpha"]].firstObject.longLongValue;

	for (int fetch = 0; fetch < 2; ++fetch) {
		XCTestExpectation *fetched = [self expectationWithDescription:@"fetch"];
		[repo fetchObjectByIdentifier:identifier completion:^(NSArray *fetchedObjects) {
			ZENSlowInitDomainObject *object = fetchedObjects.firstObject;
			XCTAssertTrue(object.initialized);
			XCTAssertEqual(object.asyncInitCount, 1);
			[fetched fulfill];
		}];
		[self waitForExpectations:@[fetched] timeout:5.0];
	}
}

- (void)testConcurrentFetchesWaitForAsyncInit {
	// The second fetch finds the object in the cache while its async init is
	// still running, and must wait for it rather than return it early
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENSlowInitDomainObject class]];
	ZENIdentifier identifier = [self insertRowsNamed:@[@"Alpha"]].firstObject.longLongValue;

	NSMutableArray<XCTestExpectation *> *expectations = [NSMutableArray new];
	for (int fetch = 0; fetch < 3; ++fetch) {
		XCTestExpectation *fetched = [self expectationWithDescription:[NSString stringWithFormat:@"fetch %d", fetch]];
		[expectations addObject:fetched];
		[repo fetchObjectByIdentifier:identifier completion:^(NSArray *fetchedObjects) {
			ZENSlowInitDomainObject *object = fetchedObjects.firstObject;
			XCTAssertTrue(object.initialized, @"Fetch %d returned an object before its async init finished", fetch);
			[fetched fulfill];
		}];
	}
	[self waitForExpectations:expectations timeout:5.0];
}

- (void)testFetchAllWaitsForAsyncInitInProgress {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENSlowInitDomainObject class]];
	ZENIdentifier identifier = [self insertRowsNamed:@[@"Alpha", @"Beta"]].firstObject.longLongValue;

	// Start one object's async init, then fetch everything while it runs
	[repo fetchObjectByIdentifier:identifier completion:^(NSArray *fetchedObjects){}];
	NSArray<ZENSlowInitDomainObject *> *objects = [self fetchAllFromRepository:repo];

	XCTAssertEqual(objects.count, 2u);
	for (ZENSlowInitDomainObject *object in objects) {
		XCTAssertTrue(object.initialized);
		XCTAssertEqual(object.asyncInitCount, 1);
	}
}

- (void)testAsyncInitCompletesOnceWhenObjectsCompleteTwice {
	NSArray *objects = @[
		[[ZENDoubleCompletionDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:1 name:@"Alpha"]],
		[[ZENDoubleCompletionDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:2 name:@"Beta"]],
	];

	XCTestExpectation *completed = [self expectationWithDescription:@"async init completed"];
	XCTestExpectation *completedAgain = [self expectationWithDescription:@"async init completed again"];
	completedAgain.inverted = YES;
	__block NSInteger completions = 0;
	[ZENDomainObject asyncInit:objects
						 model:nil
					completion:^(NSError *error) {
						XCTAssertNil(error);
						@synchronized(self) {
							completions += 1;
							[(completions == 1 ? completed : completedAgain) fulfill];
						}
					}];
	[self waitForExpectations:@[completed] timeout:5.0];
	[self waitForExpectations:@[completedAgain] timeout:0.5];
}

- (void)testAsyncInitWithNoObjectsCompletes {
	XCTestExpectation *completed = [self expectationWithDescription:@"async init completed"];
	[ZENDomainObject asyncInit:@[]
						 model:nil
					completion:^(NSError *error) {
						XCTAssertNil(error);
						[completed fulfill];
					}];
	[self waitForExpectations:@[completed] timeout:5.0];
}

#pragma mark - Async init failure

- (void)testAsyncInitReportsFailure {
	NSArray *objects = @[
		[[ZENFailableInitDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:1 name:@"Alpha"]],
		[[ZENFailableInitDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:2 name:@"Fail-Beta"]],
	];

	XCTestExpectation *completed = [self expectationWithDescription:@"async init completed"];
	[ZENDomainObject asyncInit:objects
						 model:nil
					completion:^(NSError *error) {
						XCTAssertEqualObjects(error.domain, ZENTestErrorDomain);
						[completed fulfill];
					}];
	[self waitForExpectations:@[completed] timeout:5.0];
}

- (void)testFetchAllLeavesOutObjectsWhoseInitFailed {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENFailableInitDomainObject class]];
	[self insertRowsNamed:@[@"Alpha", @"Fail-Beta", @"Gamma"]];

	NSArray<ZENTestDomainObject *> *objects = [self fetchAllFromRepository:repo];
	XCTAssertEqualObjects([objects valueForKey:@"name"], (@[@"Alpha", @"Gamma"]));
}

- (void)testFetchByIdentifierRetriesFailedInit {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENFailableInitDomainObject class]];
	ZENIdentifier identifier = [self insertRowsNamed:@[@"Fail-Alpha"]].firstObject.longLongValue;

	XCTestExpectation *failed = [self expectationWithDescription:@"fetch while init fails"];
	[repo fetchObjectByIdentifier:identifier
					   completion:^(NSArray *fetchedObjects) {
						   XCTAssertEqual(fetchedObjects.count, 0u);
						   [failed fulfill];
					   }];
	[self waitForExpectations:@[failed] timeout:5.0];

	// Fix the row, so the next fetch creates the object again and its init succeeds
	[self.queue transactionSync:^(ZENDatabase *database) {
		[[ZENTestTable new] updateDTO:[[ZENTestDTO alloc] initWithIdentifier:identifier name:@"Alpha"] database:database];
	}];

	XCTestExpectation *succeeded = [self expectationWithDescription:@"fetch after fixing the row"];
	[repo fetchObjectByIdentifier:identifier
					   completion:^(NSArray *fetchedObjects) {
						   ZENTestDomainObject *object = fetchedObjects.firstObject;
						   XCTAssertEqualObjects(object.name, @"Alpha");
						   [succeeded fulfill];
					   }];
	[self waitForExpectations:@[succeeded] timeout:5.0];
}

- (void)testFetchesWaitingOnFailingInitLeaveOutObject {
	// Later fetches find the object in the cache while its async init is still
	// running. When that init fails, none of them should return the object.
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENSlowFailingInitDomainObject class]];
	ZENIdentifier identifier = [self insertRowsNamed:@[@"Alpha"]].firstObject.longLongValue;

	XCTestExpectation *firstFetched = [self expectationWithDescription:@"first fetch"];
	[repo fetchObjectByIdentifier:identifier
					   completion:^(NSArray *fetchedObjects) {
						   XCTAssertEqual(fetchedObjects.count, 0u);
						   [firstFetched fulfill];
					   }];

	// The database queue is serial, so once this returns, the first fetch has
	// cached the object and started its init
	[self.queue fetchSync:^(ZENDatabase *database){}];

	XCTestExpectation *fetchedByIdentifier = [self expectationWithDescription:@"fetch by identifier"];
	[repo fetchObjectByIdentifier:identifier
					   completion:^(NSArray *fetchedObjects) {
						   XCTAssertEqual(fetchedObjects.count, 0u, @"Fetch by identifier returned an object whose init failed");
						   [fetchedByIdentifier fulfill];
					   }];

	XCTestExpectation *fetchedAll = [self expectationWithDescription:@"fetch all"];
	[repo fetchAllObjects:^(NSArray *fetchedObjects) {
		XCTAssertEqual(fetchedObjects.count, 0u, @"Fetch all returned an object whose init failed");
		[fetchedAll fulfill];
	}];

	[self waitForExpectations:@[firstFetched, fetchedByIdentifier, fetchedAll] timeout:5.0];
}

- (void)testAsyncInitAndAddReportsFailureWithoutAdding {
	ZENObjectRepository *repo = [self repositoryWithEmbryo:[ZENFailableInitDomainObject class]];
	ZENFailableInitDomainObject *failing = [[ZENFailableInitDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Fail-Alpha"]];
	ZENFailableInitDomainObject *succeeding = [[ZENFailableInitDomainObject alloc] initWithDTO:[[ZENTestDTO alloc] initWithIdentifier:ZENGetNextObjectIdentifier() name:@"Beta"]];

	XCTestExpectation *added = [self expectationWithDescription:@"added"];
	[repo asyncInitAndAdd:failing
			   completion:^(NSError *error) {
				   XCTAssertEqualObjects(error.domain, ZENTestErrorDomain);
				   [repo asyncInitAndAdd:succeeding
							  completion:^(NSError *error) {
								  XCTAssertNil(error);
								  [added fulfill];
							  }];
			   }];
	[self waitForExpectations:@[added] timeout:5.0];

	NSArray<ZENTestDomainObject *> *objects = [self fetchAllFromRepository:repo];
	XCTAssertEqualObjects([objects valueForKey:@"name"], (@[@"Beta"]));
}

@end
