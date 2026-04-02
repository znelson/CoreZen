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

@end
