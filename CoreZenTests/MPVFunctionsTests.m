//
//  MPVFunctionsTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

#import "MPVFunctions.h"

@interface MPVFunctionsTests : XCTestCase

@end

@implementation MPVFunctionsTests

#pragma mark - Strings from mpv

- (void)testStringFromMPVDecodesUTF8 {
	// mpv strings are UTF-8, including file paths
	NSString *expected = @"/Movies/Amélie 日本語 🎬.mp4";
	XCTAssertEqualObjects(zen_mpv_to_nsstring(expected.UTF8String), expected);
}

- (void)testStringFromMPVDecodesASCII {
	XCTAssertEqualObjects(zen_mpv_to_nsstring("mpv 0.42.0"), @"mpv 0.42.0");
}

- (void)testStringFromMPVHandlesNULL {
	XCTAssertNil(zen_mpv_to_nsstring(NULL));
}

#pragma mark - Command arguments

- (NSString *)formatDouble:(double)value {
	char buffer[32];
	zen_mpv_format_double(value, buffer, sizeof(buffer));
	return @(buffer);
}

- (void)testFormatDouble {
	XCTAssertEqualObjects([self formatDouble:1.5], @"1.500000");
	XCTAssertEqualObjects([self formatDouble:-5], @"-5.000000");
	XCTAssertEqualObjects([self formatDouble:0], @"0.000000");
	XCTAssertEqualObjects([self formatDouble:123456.789], @"123456.789000");
}

- (void)testFormatDoubleTruncatesToBuffer {
	char buffer[4];
	zen_mpv_format_double(123456.0, buffer, sizeof(buffer));
	XCTAssertEqualObjects(@(buffer), @"123");
}

@end
