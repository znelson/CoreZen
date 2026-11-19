//
//  MediaPlayerTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreAudio;
@import CoreZen;

#import "TestLog.h"

static const NSTimeInterval kPlayerTimeout = 10.0;

// Without a player view mpv has no video output, so it can only play the
// fixture's audio track, which needs an audio output device. CI machines may
// not have one.
static BOOL ZENHasAudioOutputDevice(void) {
	AudioObjectPropertyAddress address = {
		kAudioHardwarePropertyDefaultOutputDevice,
		kAudioObjectPropertyScopeGlobal,
		kAudioObjectPropertyElementMain
	};
	AudioDeviceID device = kAudioObjectUnknown;
	UInt32 size = sizeof(device);
	OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &size, &device);
	return status == noErr && device != kAudioObjectUnknown;
}

@interface MediaPlayerTests : XCTestCase

@property (nonatomic, strong) ZENMediaPlayer *player;
@property (nonatomic, strong) NSURL *temporaryDirectory;
// Every status the player reports while it's recorded
@property (nonatomic, strong) NSMutableArray<NSNumber *> *recordedStatuses;

@end

@implementation MediaPlayerTests

- (void)setUp {
	self.player = [ZENMediaPlayer new];
	XCTAssertNotNil(self.player);

	NSString *name = [NSString stringWithFormat:@"CoreZenTests-%@", NSUUID.UUID.UUIDString];
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:name];
	self.temporaryDirectory = [NSURL fileURLWithPath:path isDirectory:YES];
	NSError *error = nil;
	BOOL created = [NSFileManager.defaultManager createDirectoryAtURL:self.temporaryDirectory withIntermediateDirectories:YES attributes:nil error:&error];
	XCTAssertTrue(created, @"%@", error);
}

- (void)tearDown {
	[self.player terminatePlayer];
	self.player = nil;
	[NSFileManager.defaultManager removeItemAtURL:self.temporaryDirectory error:nil];
}

#pragma mark - Helpers

// Copies the video fixture into the temporary folder under the given name
- (NSURL *)copyVideoNamed:(NSString *)name {
	NSURL *source = [[NSBundle bundleForClass:self.class] URLForResource:@"video" withExtension:@"mp4"];
	NSURL *destination = [self.temporaryDirectory URLByAppendingPathComponent:name];
	NSError *error = nil;
	BOOL copied = [NSFileManager.defaultManager copyItemAtURL:source toURL:destination error:&error];
	XCTAssertTrue(copied, @"%@", error);
	return destination;
}

- (void)expectFileURL {
	[self keyValueObservingExpectationForObject:self.player
										keyPath:@"fileURL"
										handler:^BOOL(id player, NSDictionary *change) {
											return [player fileURL] != nil;
										}];
}

// Loads a file and waits for the player to report its fileURL, which mpv does
// as soon as the file starts loading
- (NSURL *)loadFileURL:(NSURL *)url {
	[self expectFileURL];
	[self.player loadFileURL:url];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
	return self.player.fileURL;
}

// Loads a file and waits until it can seek. mpv reports a position only once
// the file has loaded, and drops seeks sent before then.
- (void)loadFileURLReadyToSeek:(NSURL *)url {
	[self expectFileURL];
	[self keyValueObservingExpectationForObject:self.player keyPath:@"positionPercent" handler:nil];
	[self.player loadFileURL:url];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)assertFileURL:(NSURL *)fileURL isURL:(NSURL *)url {
	XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:fileURL.path], @"No file at %@", fileURL.path);
	// The file system may hand back decomposed Unicode, so compare canonical forms
	XCTAssertEqualObjects(fileURL.path.precomposedStringWithCanonicalMapping, url.path.precomposedStringWithCanonicalMapping);
}

#pragma mark - File URL

- (void)testFileURLMatchesLoadedFile {
	NSURL *url = [self copyVideoNamed:@"video.mp4"];
	[self assertFileURL:[self loadFileURL:url] isURL:url];
}

- (void)testFileURLMatchesLoadedFileWithNonASCIIName {
	NSURL *url = [self copyVideoNamed:@"Amélie 日本語 🎬.mp4"];
	[self assertFileURL:[self loadFileURL:url] isURL:url];
}

#pragma mark - Seeking

- (void)expectPositionPercentNear:(double)percent {
	[self keyValueObservingExpectationForObject:self.player
										keyPath:@"positionPercent"
										handler:^BOOL(id player, NSDictionary *change) {
											return fabs([player positionPercent] - percent) < 5.0;
										}];
}

- (void)testSeekAbsoluteSeconds {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	[self expectPositionPercentNear:50.0];
	[self.player seekAbsoluteSeconds:1.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testSeekAbsolutePercentage {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	[self expectPositionPercentNear:75.0];
	[self.player seekAbsolutePercentage:75.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testSeekRightAfterLoadIsApplied {
	// mpv rejects seeks until the file has loaded, so the player has to hold
	// this one, e.g. for resuming playback at a saved position
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self expectPositionPercentNear:50.0];
	[self.player loadFileURL:[self copyVideoNamed:@"video.mp4"]];
	[self.player seekAbsoluteSeconds:1.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testLatestSeekWinsWhileSeeking {
	// Like scrubbing with the slider: the last position asked for must be
	// where playback ends up, even if it arrives while a seek is running
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	[self expectPositionPercentNear:75.0];
	[self.player seekAbsolutePercentage:25.0];
	[self.player seekAbsolutePercentage:75.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testRelativeSeeksWhileSeekingAddUp {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	// Three half-second steps from the start of the 2 second video
	[self expectPositionPercentNear:75.0];
	[self.player seekRelativeSeconds:0.5];
	[self.player seekRelativeSeconds:0.5];
	[self.player seekRelativeSeconds:0.5];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testRejectedSeekDoesNotBlockLaterSeeks {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];

	// mpv rejects a non-numeric target outright
	[self.player seekAbsoluteSeconds:NAN];
	XCTAssertFalse(self.player.seeking);

	[self expectPositionPercentNear:50.0];
	[self.player seekAbsoluteSeconds:1.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

- (void)testSeekWithNoFileLoadedDoesNotLeaveSeekingSet {
	[self.player seekAbsoluteSeconds:1.0];
	XCTAssertFalse(self.player.seeking);
}

#pragma mark - Status

static void *StatusContext = &StatusContext;

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary<NSKeyValueChangeKey, id> *)change
					   context:(void *)context {
	if (context == StatusContext) {
		[self.recordedStatuses addObject:change[NSKeyValueChangeNewKey]];
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)waitForStatus:(ZENMediaPlayerStatus)status {
	if (self.player.status != status) {
		[self keyValueObservingExpectationForObject:self.player keyPath:@"status" expectedValue:@(status)];
		[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
	}
}

- (void)testStatusBeforeLoading {
	XCTAssertEqual(self.player.status, ZENMediaPlayerStatusIdle);
	XCTAssertNil(self.player.error);
	XCTAssertEqual(self.player.positionSeconds, 0.0);
	XCTAssertEqual(self.player.durationSeconds, 0.0);
}

- (void)testStatusIsLoadingUntilFileLoads {
	[self.player loadFileURL:[self copyVideoNamed:@"video.mp4"]];
	XCTAssertEqual(self.player.status, ZENMediaPlayerStatusLoading);
	[self waitForStatus:ZENMediaPlayerStatusReady];
	XCTAssertNil(self.player.error);
}

- (void)testMissingFileFails {
	NSURL *url = [self.temporaryDirectory URLByAppendingPathComponent:@"missing.mp4"];
	[self.player loadFileURL:url];
	[self waitForStatus:ZENMediaPlayerStatusFailed];

	NSError *error = self.player.error;
	XCTAssertEqualObjects(error.domain, ZENMediaPlayerErrorDomain);
	XCTAssertEqual(error.code, ZENMediaPlayerErrorPlaybackFailed);
	XCTAssertEqualObjects(error.userInfo[NSURLErrorKey], url);
	XCTAssertTrue([error.localizedDescription containsString:@"missing.mp4"], @"%@", error.localizedDescription);
}

// A file of random bytes, with a video's name
- (NSURL *)fileThatIsNotVideo {
	NSURL *url = [self.temporaryDirectory URLByAppendingPathComponent:@"not-a-video.mp4"];
	uint8_t bytes[4096];
	arc4random_buf(bytes, sizeof(bytes));
	XCTAssertTrue([[NSData dataWithBytes:bytes length:sizeof(bytes)] writeToURL:url atomically:YES]);
	return url;
}

- (void)testFileThatIsNotVideoFails {
	[self.player loadFileURL:[self fileThatIsNotVideo]];
	[self waitForStatus:ZENMediaPlayerStatusFailed];
	XCTAssertNotNil(self.player.error);
}

- (void)testMpvErrorsAreLoggedAsErrors {
	NSDate *start = [NSDate date];
	[self.player loadFileURL:[self fileThatIsNotVideo]];
	[self waitForStatus:ZENMediaPlayerStatusFailed];

	// mpv logs why it couldn't play the file, at its error level. The reason
	// itself is private, so it can show as <private>.
	NSArray<OSLogEntryLog *> *errors = ZENCoreZenLogEntries(ZENLogEntriesSince(start), @"Player", OSLogEntryLogLevelError, @"mpv [cplayer] error: ");
	XCTAssertGreaterThan(errors.count, 0u);
}

- (void)testReplacingFileGoesStraightToLoading {
	// mpv reports the file it's replacing as stopped after it starts on the next
	// one, which mustn't make the player look stopped while the next one loads
	[self.player loadFileURL:[self copyVideoNamed:@"first.mp4"]];
	[self waitForStatus:ZENMediaPlayerStatusReady];

	self.recordedStatuses = [NSMutableArray new];
	[self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:StatusContext];
	[self.player loadFileURL:[self copyVideoNamed:@"second.mp4"]];
	[self waitForStatus:ZENMediaPlayerStatusReady];
	// Let any event about the first file arrive, too
	XCTestExpectation *settled = [self expectationWithDescription:@"settled"];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		[settled fulfill];
	});
	[self waitForExpectations:@[settled] timeout:kPlayerTimeout];
	[self.player removeObserver:self forKeyPath:@"status" context:StatusContext];

	NSArray *expected = @[@(ZENMediaPlayerStatusLoading), @(ZENMediaPlayerStatusReady)];
	XCTAssertEqualObjects(self.recordedStatuses, expected);
}

- (void)testLoadsBackToBackEndReadyWithTheLast {
	// mpv never starts the first, so nothing about it ever arrives
	[self.player loadFileURL:[self copyVideoNamed:@"first.mp4"]];
	NSURL *second = [self copyVideoNamed:@"second.mp4"];
	[self.player loadFileURL:second];
	[self waitForStatus:ZENMediaPlayerStatusReady];
	[self assertFileURL:self.player.fileURL isURL:second];
}

- (void)testLoadingAnotherFileClearsTheError {
	[self.player loadFileURL:[self.temporaryDirectory URLByAppendingPathComponent:@"missing.mp4"]];
	[self waitForStatus:ZENMediaPlayerStatusFailed];

	[self.player loadFileURL:[self copyVideoNamed:@"video.mp4"]];
	XCTAssertNil(self.player.error);
	[self waitForStatus:ZENMediaPlayerStatusReady];
	XCTAssertNil(self.player.error);
}

- (void)testPlayingToTheEndEnds {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Playing needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	[self.player seekAbsoluteSeconds:1.8];
	[self.player startPlayback];
	[self waitForStatus:ZENMediaPlayerStatusEnded];
	XCTAssertNil(self.player.error);
}

#pragma mark - Time

- (void)testDurationIsKnownOnceLoaded {
	[self keyValueObservingExpectationForObject:self.player
										keyPath:@"durationSeconds"
										handler:^BOOL(id player, NSDictionary *change) {
											return [player durationSeconds] > 0;
										}];
	[self.player loadFileURL:[self copyVideoNamed:@"video.mp4"]];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
	XCTAssertEqualWithAccuracy(self.player.durationSeconds, 2.0, 0.1);
}

- (void)testPositionSecondsFollowsSeek {
	XCTSkipUnless(ZENHasAudioOutputDevice(), @"Seeking needs mpv to play audio, and there's no audio output device");
	[self loadFileURLReadyToSeek:[self copyVideoNamed:@"video.mp4"]];
	[self keyValueObservingExpectationForObject:self.player
										keyPath:@"positionSeconds"
										handler:^BOOL(id player, NSDictionary *change) {
											return fabs([player positionSeconds] - 1.0) < 0.15;
										}];
	[self.player seekAbsoluteSeconds:1.0];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
}

@end
