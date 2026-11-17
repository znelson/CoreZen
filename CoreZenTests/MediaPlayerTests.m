//
//  MediaPlayerTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreAudio;
@import CoreZen;

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

@end
