//
//  CoreZenTests.m
//  CoreZenTests
//
//  Created by Zach Nelson on 7/18/22.
//

#import <XCTest/XCTest.h>

@import CoreZen;

@interface CoreZenTests : XCTestCase

@end

@implementation CoreZenTests

- (void)testFrameworkLoads {
	XCTAssertTrue(CoreZenVersionNumber > 0, @"CoreZen framework should report a version number");
}

@end
