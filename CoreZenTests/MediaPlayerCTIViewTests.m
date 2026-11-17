//
//  MediaPlayerCTIViewTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

static const NSTimeInterval kPreviewTimeout = 10.0;

// Private members of ZENMediaPlayerCTIView that these tests look at
@interface ZENMediaPlayerCTIView (Testing)

- (NSArray<ZENRenderedFrame *> *)previewFrames;
- (void)updateMediaFile:(NSURL *)url;

@end

@interface MediaPlayerCTIViewTests : XCTestCase

@property (nonatomic, strong) ZENMediaPlayerCTIView *view;

@end

@implementation MediaPlayerCTIViewTests

- (void)setUp {
	self.view = [[ZENMediaPlayerCTIView alloc] initWithFrame:NSMakeRect(0, 0, 400, 40)];
}

- (void)tearDown {
	// Stops any preview rendering and closes the media file
	[self.view updateMediaFile:nil];
	self.view = nil;
}

- (NSURL *)fixtureNamed:(NSString *)name {
	NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:name withExtension:nil];
	XCTAssertNotNil(url, @"Missing test resource %@", name);
	return url;
}

// Waits for previewFrames to be set to a non-nil value, and reports whether
// that happened on the main thread
- (BOOL)waitForPreviewFrames {
	__block BOOL onMainThread = YES;
	[self keyValueObservingExpectationForObject:self.view
										keyPath:@"previewFrames"
										handler:^BOOL(id view, NSDictionary *change) {
											if (![view previewFrames]) {
												return NO;
											}
											onMainThread = NSThread.isMainThread;
											return YES;
										}];
	[self waitForExpectationsWithTimeout:kPreviewTimeout handler:nil];
	return onMainThread;
}

- (void)testPreviewFramesAreSetOnMainThread {
	// The view reads previewFrames on the main thread when the mouse moves
	[self.view updateMediaFile:[self fixtureNamed:@"video.mp4"]];
	XCTAssertTrue([self waitForPreviewFrames], @"previewFrames was set off the main thread");
	XCTAssertEqual(self.view.previewFrames.count, 101u);
}

- (void)testLatestFileWinsWhenFilesChangeQuickly {
	// Previews still being made for the first file must not replace the
	// second file's. The audio-only file has no frames to preview.
	[self.view updateMediaFile:[self fixtureNamed:@"video.mp4"]];
	[self.view updateMediaFile:[self fixtureNamed:@"audio.m4a"]];
	[self waitForPreviewFrames];
	XCTAssertEqual(self.view.previewFrames.count, 0u);

	// Give stale video previews a chance to arrive
	XCTestExpectation *stale = [self keyValueObservingExpectationForObject:self.view keyPath:@"previewFrames" handler:nil];
	stale.inverted = YES;
	[self waitForExpectations:@[stale] timeout:0.5];
	XCTAssertEqual(self.view.previewFrames.count, 0u);
}

- (void)testClearingFileClearsPreviews {
	[self.view updateMediaFile:[self fixtureNamed:@"video.mp4"]];
	[self waitForPreviewFrames];
	XCTAssertGreaterThan(self.view.previewFrames.count, 0u);

	[self.view updateMediaFile:nil];
	XCTAssertNil(self.view.previewFrames);
}

@end
