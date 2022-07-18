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

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testRelativePath {
	NSURL *urlOne = [NSURL fileURLWithPath:@"/Users/Alchemist" isDirectory:YES];
	
	NSString *relativePath = @"Documents/foo.pdf";
	NSURL *urlTwo = [NSURL URLWithString:relativePath relativeToURL:urlOne];
	
	NSString *anotherRelativePath = [urlOne zen_relativePathToURL:urlTwo];
	if (anotherRelativePath) {
		XCTAssert([relativePath isEqualToString:anotherRelativePath], @"Relative paths should match, %@ != %@", relativePath, anotherRelativePath);
	} else {
		XCTFail(@"NSURL zen_relativePathToURL: failed, %@ vs %@", urlOne, urlTwo);
	}
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
			XCTAssert([volumeName isEqual:anotherVolumeName], @"Volume names should match, %@ != %@", volumeName, anotherVolumeName);
			XCTAssert([volumeURL isEqual:anotherVolumeURL]);
		} else {
			XCTFail(@"NSURL zen_volumeInfoForUUID:volumeName:volumeURL: failed, UUID: %@", volumeUUID);
		}
	} else {
		XCTFail(@"NSURL zen_volumeName:volumeURL:volumeUUID:error: failed, URL: %@, error: %@", url, error);
	}
}

@end
