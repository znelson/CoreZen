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

#pragma mark - ObjectRepository Integration

- (void)testRepositoryAddAndFetch {
	XCTestExpectation *expectation = [self expectationWithDescription:@"add and fetch"];

	ZENObjectRepository *repo = [[ZENObjectRepository alloc]
		 initWithDataModel:nil
				tableClass:[ZENTestTable class]
			 databaseQueue:self.queue
		domainObjectEmbryo:[ZENTestDomainObject class]
				 cacheType:ZENObjectRepositoryCacheType_Strong];

	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"RepoTest"];
	ZENTestDomainObject *obj = [[ZENTestDomainObject alloc] initWithDTO:dto];

	[repo addObject:obj completion:^{
		[repo fetchObjectByIdentifier:id1 completion:^(NSArray *fetchedObjects) {
			XCTAssertEqual(fetchedObjects.count, 1u);
			ZENTestDomainObject *fetched = fetchedObjects.firstObject;
			XCTAssertEqual(fetched.identifier, id1);
			[expectation fulfill];
		}];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRepositoryDeleteObject {
	XCTestExpectation *expectation = [self expectationWithDescription:@"delete"];

	ZENObjectRepository *repo = [[ZENObjectRepository alloc]
		 initWithDataModel:nil
				tableClass:[ZENTestTable class]
			 databaseQueue:self.queue
		domainObjectEmbryo:[ZENTestDomainObject class]
				 cacheType:ZENObjectRepositoryCacheType_Strong];

	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"ToDelete"];
	ZENTestDomainObject *obj = [[ZENTestDomainObject alloc] initWithDTO:dto];

	[repo addObject:obj completion:^{
		[repo deleteObject:obj completion:^{
			[repo countAllObjects:^(NSUInteger count) {
				XCTAssertEqual(count, 0u);
				[expectation fulfill];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRepositoryCountAllObjects {
	XCTestExpectation *expectation = [self expectationWithDescription:@"count"];

	ZENObjectRepository *repo = [[ZENObjectRepository alloc]
		 initWithDataModel:nil
				tableClass:[ZENTestTable class]
			 databaseQueue:self.queue
		domainObjectEmbryo:[ZENTestDomainObject class]
				 cacheType:ZENObjectRepositoryCacheType_Strong];

	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENIdentifier id2 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto1 = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"One"];
	ZENTestDTO *dto2 = [[ZENTestDTO alloc] initWithIdentifier:id2 name:@"Two"];

	[repo addObject:[[ZENTestDomainObject alloc] initWithDTO:dto1] completion:^{
		[repo addObject:[[ZENTestDomainObject alloc] initWithDTO:dto2] completion:^{
			[repo countAllObjects:^(NSUInteger count) {
				XCTAssertEqual(count, 2u);
				[expectation fulfill];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRepositoryFetchAllObjects {
	XCTestExpectation *expectation = [self expectationWithDescription:@"fetch all"];

	ZENObjectRepository *repo = [[ZENObjectRepository alloc]
		 initWithDataModel:nil
				tableClass:[ZENTestTable class]
			 databaseQueue:self.queue
		domainObjectEmbryo:[ZENTestDomainObject class]
				 cacheType:ZENObjectRepositoryCacheType_Strong];

	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENIdentifier id2 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto1 = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Alpha"];
	ZENTestDTO *dto2 = [[ZENTestDTO alloc] initWithIdentifier:id2 name:@"Beta"];

	[repo addObject:[[ZENTestDomainObject alloc] initWithDTO:dto1] completion:^{
		[repo addObject:[[ZENTestDomainObject alloc] initWithDTO:dto2] completion:^{
			[repo fetchAllObjects:^(NSArray *fetchedObjects) {
				XCTAssertEqual(fetchedObjects.count, 2u);
				[expectation fulfill];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testRepositoryUpdateObject {
	XCTestExpectation *expectation = [self expectationWithDescription:@"update"];

	ZENObjectRepository *repo = [[ZENObjectRepository alloc]
		 initWithDataModel:nil
				tableClass:[ZENTestTable class]
			 databaseQueue:self.queue
		domainObjectEmbryo:[ZENTestDomainObject class]
				 cacheType:ZENObjectRepositoryCacheType_Strong];

	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestDTO *dto = [[ZENTestDTO alloc] initWithIdentifier:id1 name:@"Original"];
	ZENTestDomainObject *obj = [[ZENTestDomainObject alloc] initWithDTO:dto];

	[repo addObject:obj completion:^{
		// Mutate the DTO's name and push the update through the repository
		dto.name = @"Updated";
		[repo updateObject:obj completion:^{
			// Verify the database row was changed by reading it directly
			[self.queue fetchSync:^(ZENDatabase *database) {
				ZENTestTable *table = [ZENTestTable new];
				ZENResultSet *rs = [table rowByIdentifier:id1 database:database];
				XCTAssertTrue([rs next]);
				ZENTestDTO *fetched = (ZENTestDTO *)[table dtoFromRow:rs];
				XCTAssertEqualObjects(fetched.name, @"Updated");
				[rs close];
				[expectation fulfill];
			}];
		}];
	}];

	[self waitForExpectationsWithTimeout:5.0 handler:nil];
}

#pragma mark - Async init

- (ZENObjectRepository *)repositoryWithEmbryo:(Class<ZENDomainObject>)embryo {
	return [[ZENObjectRepository alloc] initWithDataModel:nil
											   tableClass:[ZENTestTable class]
											databaseQueue:self.queue
									   domainObjectEmbryo:embryo
												cacheType:ZENObjectRepositoryCacheType_Strong];
}

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
					completion:^{
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
					completion:^{
						[completed fulfill];
					}];
	[self waitForExpectations:@[completed] timeout:5.0];
}

@end
