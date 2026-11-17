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
	self.cache = [ZENObjectCache weakObjectCache];
	XCTAssertNotNil(self.cache);
	ZENSetLargestObjectIdentifier(0);
}

#pragma mark - Identifiers

- (void)testIdentifiers {
	ZENIdentifier nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssertEqual(nextIdentifier, 1);

	nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssertEqual(nextIdentifier, 2);

	ZENTestIdentifiable *obj = [ZENTestIdentifiable new];
	XCTAssertEqual(obj.identifier, 3);

	nextIdentifier = ZENGetNextObjectIdentifier();
	XCTAssertEqual(nextIdentifier, 4);
}

#pragma mark - Cache / Retrieve

- (void)testNonExistingObject {
	ZENSetLargestObjectIdentifier(2);
	ZENIdentifier identifier = ZENGetNextObjectIdentifier();
	XCTAssertEqual(identifier, 3);

	ZENTestIdentifiable *obj = [ZENTestIdentifiable testIdentifiableWithIdentifier:identifier];
	[self.cache cacheObject:obj];

	id<ZENIdentifiable> cachedObject = [self.cache cachedObject:1];
	XCTAssertNil(cachedObject);
}

- (void)testExistingObject {
	ZENSetLargestObjectIdentifier(201);
	ZENIdentifier identifier = ZENGetNextObjectIdentifier();
	XCTAssertEqual(identifier, 202);

	ZENTestIdentifiable *objOne = [ZENTestIdentifiable testIdentifiableWithIdentifier:identifier];
	[self.cache cacheObject:objOne];

	ZENTestIdentifiable *objTwo = [self.cache cachedObject:objOne.identifier];
	XCTAssertEqual(objOne, objTwo);
	XCTAssertEqual(objOne.identifier, objTwo.identifier);
}

#pragma mark - Remove

- (void)testRemoveObject {
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();
	ZENTestIdentifiable *obj = [ZENTestIdentifiable testIdentifiableWithIdentifier:id1];
	[self.cache cacheObject:obj];

	XCTAssertNotNil([self.cache cachedObject:id1]);

	[self.cache removeObject:id1];

	// removeObject uses dispatch_barrier_async, give it a moment to complete
	NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:1.0];
	while ([self.cache cachedObject:id1] != nil && [timeout timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}
	XCTAssertNil([self.cache cachedObject:id1], @"Object should be removed from cache");
}

#pragma mark - All Cached Objects

- (void)testAllCachedObjects {
	ZENObjectCache *strongCache = [ZENObjectCache strongObjectCache];

	ZENTestIdentifiable *a = [ZENTestIdentifiable testIdentifiableWithIdentifier:ZENGetNextObjectIdentifier()];
	ZENTestIdentifiable *b = [ZENTestIdentifiable testIdentifiableWithIdentifier:ZENGetNextObjectIdentifier()];
	ZENTestIdentifiable *c = [ZENTestIdentifiable testIdentifiableWithIdentifier:ZENGetNextObjectIdentifier()];

	[strongCache cacheObject:a];
	[strongCache cacheObject:b];
	[strongCache cacheObject:c];

	// cacheObject uses dispatch_barrier_async, allow it to settle
	NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:1.0];
	while ([strongCache allCachedObjects].count < 3 && [timeout timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}

	NSArray *all = [strongCache allCachedObjects];
	XCTAssertEqual(all.count, 3u);
}

#pragma mark - Remove All

- (void)testRemoveAllObjects {
	ZENObjectCache *strongCache = [ZENObjectCache strongObjectCache];

	[strongCache cacheObject:[ZENTestIdentifiable testIdentifiableWithIdentifier:ZENGetNextObjectIdentifier()]];
	[strongCache cacheObject:[ZENTestIdentifiable testIdentifiableWithIdentifier:ZENGetNextObjectIdentifier()]];

	[strongCache removeAllObjects];

	// Both removeAllObjects and cacheObject use dispatch_barrier_async
	NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:1.0];
	while ([strongCache allCachedObjects].count > 0 && [timeout timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}

	XCTAssertEqual([strongCache allCachedObjects].count, 0u, @"Cache should be empty after removeAll");
}

#pragma mark - Strong vs Weak

- (void)testStrongCacheRetainsObject {
	ZENObjectCache *strongCache = [ZENObjectCache strongObjectCache];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();

	@autoreleasepool {
		ZENTestIdentifiable *obj = [ZENTestIdentifiable testIdentifiableWithIdentifier:id1];
		[strongCache cacheObject:obj];
	}

	// cacheObject is barrier-async; wait for it to land
	NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:1.0];
	while ([strongCache cachedObject:id1] == nil && [timeout timeIntervalSinceNow] > 0) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
	}

	XCTAssertNotNil([strongCache cachedObject:id1],
					@"Strong cache should keep the object alive after external refs are released");
}

- (void)testWeakCacheReleasesObject {
	ZENObjectCache *weakCache = [ZENObjectCache weakObjectCache];
	ZENIdentifier id1 = ZENGetNextObjectIdentifier();

	@autoreleasepool {
		ZENTestIdentifiable *obj = [ZENTestIdentifiable testIdentifiableWithIdentifier:id1];
		[weakCache cacheObject:obj];

		// Barrier-async write; wait for it to land before leaving the pool
		NSDate *timeout = [NSDate dateWithTimeIntervalSinceNow:1.0];
		while ([weakCache cachedObject:id1] == nil && [timeout timeIntervalSinceNow] > 0) {
			[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		}
		XCTAssertNotNil([weakCache cachedObject:id1], @"Object should be in cache while alive");
	}

	// After the autorelease pool drains, the weak reference should clear
	XCTAssertNil([weakCache cachedObject:id1],
				 @"Weak cache should release the object when no external strong refs remain");
}

@end
