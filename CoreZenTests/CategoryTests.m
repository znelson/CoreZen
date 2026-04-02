//
//  CategoryTests.m
//  CoreZenTests
//
//  Created by Zach Nelson on 7/18/22.
//

#import <XCTest/XCTest.h>

@import CoreZen;

@interface CategoryTests : XCTestCase

@end

@implementation CategoryTests

#pragma mark - NSURL+CoreZen

- (void)testRelativePath {
	NSURL *base = [NSURL fileURLWithPath:@"/Users/CoreZen" isDirectory:YES];
	NSURL *child = [NSURL fileURLWithPath:@"/Users/CoreZen/Documents/foo.pdf"];
	
	NSString *relativePath = [base zen_relativePathToURL:child];
	XCTAssertNotNil(relativePath, @"Should produce a relative path");
	// Implementation strips base path prefix, leaving the separator
	XCTAssertEqualObjects(relativePath, @"/Documents/foo.pdf");
}

- (void)testRelativePathReturnsNilForUnrelatedURLs {
	NSURL *urlOne = [NSURL fileURLWithPath:@"/Users/Alpha" isDirectory:YES];
	NSURL *urlTwo = [NSURL fileURLWithPath:@"/Users/Beta/file.txt"];
	
	NSString *relativePath = [urlOne zen_relativePathToURL:urlTwo];
	XCTAssertNil(relativePath, @"Unrelated URLs should not produce a relative path");
}

- (void)testVolumeInfo {
	NSURL *url = [NSURL fileURLWithPath:@"/Users" isDirectory:YES];
	NSString *volumeName;
	NSURL *volumeURL;
	NSUUID *volumeUUID;
	NSError *error;
	
	if ([url zen_volumeName:&volumeName volumeURL:&volumeURL volumeUUID:&volumeUUID error:&error]) {
		NSString *anotherVolumeName;
		NSURL *anotherVolumeURL;
		
		if ([NSURL zen_volumeInfoForUUID:volumeUUID volumeName:&anotherVolumeName volumeURL:&anotherVolumeURL]) {
			XCTAssertEqualObjects(volumeName, anotherVolumeName, @"Volume names should match");
			XCTAssertEqualObjects(volumeURL, anotherVolumeURL, @"Volume URLs should match");
		} else {
			XCTFail(@"NSURL zen_volumeInfoForUUID:volumeName:volumeURL: failed, UUID: %@", volumeUUID);
		}
	} else {
		XCTFail(@"NSURL zen_volumeName:volumeURL:volumeUUID:error: failed, URL: %@, error: %@", url, error);
	}
}

- (void)testFileSizeReturnsZeroForNonexistentFile {
	NSURL *url = [NSURL fileURLWithPath:@"/tmp/corezen_nonexistent_test_file.xyz"];
	NSUInteger size = [url zen_fileSize];
	XCTAssertEqual(size, 0u, @"File size of a nonexistent file should be 0");
}

- (void)testFileSizeForRealFile {
	NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"corezen_size_test.txt"];
	NSData *data = [@"Hello CoreZen" dataUsingEncoding:NSUTF8StringEncoding];
	[data writeToFile:tmpPath atomically:YES];

	NSURL *url = [NSURL fileURLWithPath:tmpPath];
	NSUInteger size = [url zen_fileSize];
	XCTAssertEqual(size, data.length, @"File size should match the data written");

	[[NSFileManager defaultManager] removeItemAtPath:tmpPath error:nil];
}

#pragma mark - NSNumber+CoreZen

- (void)testRandomIntegerReturnsValues {
	NSInteger a = [NSNumber zen_randomInteger];
	NSInteger b = [NSNumber zen_randomInteger];
	// Probability of collision on 64-bit random values is negligible
	XCTAssertNotEqual(a, b, @"Two random integers should differ (statistically)");
}

#pragma mark - NSFileManager+CoreZen

- (void)testFindOrCreateDirectoryInTemp {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	NSURL *url = [fm zen_findOrCreateURLForDirectory:NSCachesDirectory
											inDomain:NSUserDomainMask
								 appendPathComponent:@"CoreZenTestDir"
											  create:YES
											   error:&error];
	XCTAssertNotNil(url, @"Should return a URL, error: %@", error);
	
	BOOL isDir = NO;
	BOOL exists = [fm fileExistsAtPath:url.path isDirectory:&isDir];
	XCTAssertTrue(exists, @"Directory should exist");
	XCTAssertTrue(isDir, @"Path should be a directory");
	
	[fm removeItemAtURL:url error:nil];
}

- (void)testFindOrCreateDirectoryWithoutAppend {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error;
	NSURL *url = [fm zen_findOrCreateURLForDirectory:NSCachesDirectory
											inDomain:NSUserDomainMask
								 appendPathComponent:nil
											  create:NO
											   error:&error];
	XCTAssertNotNil(url, @"Should return the caches directory, error: %@", error);
}

@end
