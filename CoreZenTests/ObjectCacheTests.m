//
//  ObjectCacheTests.m
//  CoreZenTests
//
//  Created by Zach Nelson on 7/18/22.
//

#import <XCTest/XCTest.h>

@import CoreZen;
#import "TestIdentifiable.h"

@interface ObjectCacheTests : XCTestCase

@property (strong, nonatomic) ZENObjectCache* cache;

@end

@implementation ObjectCacheTests

- (void)setUp {
	// Put setup code here. This method is called before the invocation of each test method in the class.
	
	self.cache = [ZENObjectCache weakObjectCache];
	XCTAssert(self.cache);
	
	ZENSetLargestObjectIdentifier(0);
}

- (void)tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testIdentifiers {
	ZENIdentifier nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssert(nextIdentifier == 1);
	
	nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssert(nextIdentifier == 2);
	
	ZENTestIdentifiable* obj = [ZENTestIdentifiable new];
	ZENIdentifier objID = obj.identifier;
	XCTAssert(objID == 3);
	
	nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssert(nextIdentifier == 4);
}

- (void)testNonExistingObject {
	ZENSetLargestObjectIdentifier(2);
	ZENIdentifier identifier = ZENGetNextObjectIdentifier();
	XCTAssert(identifier == 3);
	
	ZENTestIdentifiable* obj = [ZENTestIdentifiable testIdentifiableWithIdentifier:identifier];
	[self.cache cacheObject:obj];
	
	id<ZENIdentifiable> cachedObject = [self.cache cachedObject:1];
	XCTAssert(cachedObject == nil);
}

- (void)testExistingObject {
	ZENSetLargestObjectIdentifier(201);
	ZENIdentifier identifier = ZENGetNextObjectIdentifier();
	XCTAssert(identifier == 202);
	
	ZENTestIdentifiable* objOne = [ZENTestIdentifiable testIdentifiableWithIdentifier:identifier];
	[self.cache cacheObject:objOne];
	
	ZENIdentifier objOneID = objOne.identifier;
	ZENTestIdentifiable* objTwo = [self.cache cachedObject:objOneID];

	XCTAssert(objOne == objTwo);
	XCTAssert(objOneID == objTwo.identifier);
}

@end
