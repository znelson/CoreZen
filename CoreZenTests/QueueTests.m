//
//  QueueTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

@interface QueueTests : XCTestCase

@end

@implementation QueueTests

#pragma mark - Token

- (void)testTokenStartsDeactivated {
	ZENWorkQueueToken *token = [ZENWorkQueueToken new];
	XCTAssertFalse(token.activated);
	XCTAssertFalse(token.canceled);
	XCTAssertFalse(token.terminated);
}

- (void)testTokenActivation {
	ZENWorkQueueToken *token = [ZENWorkQueueToken new];
	BOOL didActivate = [token activate];
	XCTAssertTrue(didActivate, @"First activation should succeed");
	XCTAssertTrue(token.activated);
}

- (void)testTokenDoubleActivationReturnsFalse {
	ZENWorkQueueToken *token = [ZENWorkQueueToken new];
	[token activate];
	BOOL secondActivate = [token activate];
	XCTAssertFalse(secondActivate, @"Second activation should fail");
	XCTAssertTrue(token.activated, @"Token should remain activated");
}

- (void)testTokenCancelSynonymForActivate {
	ZENWorkQueueToken *token = [ZENWorkQueueToken new];
	BOOL didCancel = [token cancel];
	XCTAssertTrue(didCancel);
	XCTAssertTrue(token.canceled);
	XCTAssertTrue(token.activated);
}

- (void)testTokenTerminateSynonymForActivate {
	ZENWorkQueueToken *token = [ZENWorkQueueToken new];
	BOOL didTerminate = [token terminate];
	XCTAssertTrue(didTerminate);
	XCTAssertTrue(token.terminated);
	XCTAssertTrue(token.activated);
}

#pragma mark - WorkQueue Creation

- (void)testCreateWorkQueue {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.queue"];
	XCTAssertNotNil(queue);
	XCTAssertEqualObjects(queue.label, @"test.queue");
	[queue terminate:^{}];
}

- (void)testCreateWorkQueueWithQoS {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.qos" qos:QOS_CLASS_UTILITY];
	XCTAssertNotNil(queue);
	XCTAssertEqualObjects(queue.label, @"test.qos");
	[queue terminate:^{}];
}

#pragma mark - Sync Execution

- (void)testSyncBlockIsCalled {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.sync"];
	__block BOOL called = NO;

	BOOL result = [queue sync:^{
		called = YES;
	}];

	XCTAssertTrue(result, @"sync should return YES when block is called");
	XCTAssertTrue(called, @"Block should have been called synchronously");
	[queue terminate:^{}];
}

- (void)testSyncAfterTerminateReturnsFalse {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.sync.term"];
	[queue terminate:^{}];

	BOOL result = [queue sync:^{}];
	XCTAssertFalse(result, @"sync after terminate should return NO");
}

#pragma mark - Async Execution

- (void)testAsyncBlockIsCalled {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.async"];
	XCTestExpectation *expectation = [self expectationWithDescription:@"async block called"];

	ZENWorkQueueToken *token = [queue async:^(ZENWorkQueueToken *canceled) {
		XCTAssertFalse(canceled.canceled, @"Should not be canceled");
		[expectation fulfill];
	}];

	XCTAssertNotNil(token, @"Should return a cancel token");
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[queue terminate:^{}];
}

- (void)testAsyncAfterTerminateReturnsNil {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.async.term"];
	[queue terminate:^{}];

	ZENWorkQueueToken *token = [queue async:^(ZENWorkQueueToken *canceled) {
		XCTFail(@"Block should not be called after terminate");
	}];
	XCTAssertNil(token, @"async after terminate should return nil");
}

#pragma mark - Cancellation

- (void)testCancelTokenReflectsInBlock {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.cancel"];
	XCTestExpectation *expectation = [self expectationWithDescription:@"cancel check"];

	// Queue a slow first job to give us time to cancel the second
	[queue async:^(ZENWorkQueueToken *canceled) {
		[NSThread sleepForTimeInterval:0.1];
	}];

	ZENWorkQueueToken *cancelToken = [queue async:^(ZENWorkQueueToken *canceled) {
		// The composite token should see our cancellation
		XCTAssertTrue(canceled.canceled, @"Should see cancellation");
		[expectation fulfill];
	}];

	[cancelToken cancel];
	[self waitForExpectationsWithTimeout:5.0 handler:nil];
	[queue terminate:^{}];
}

#pragma mark - Termination

- (void)testTerminateCallsBlock {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.terminate"];
	__block BOOL terminateCalled = NO;

	[queue terminate:^{
		terminateCalled = YES;
	}];

	XCTAssertTrue(terminateCalled, @"Terminate block should be called synchronously");
}

- (void)testSyncPreservesOrder {
	ZENWorkQueue *queue = [ZENWorkQueue workQueue:@"test.order"];
	NSMutableArray *order = [NSMutableArray new];

	[queue sync:^{ [order addObject:@1]; }];
	[queue sync:^{ [order addObject:@2]; }];
	[queue sync:^{ [order addObject:@3]; }];

	NSArray *expected = @[@1, @2, @3];
	XCTAssertEqualObjects(order, expected, @"Sync blocks should execute in order");
	[queue terminate:^{}];
}

@end
