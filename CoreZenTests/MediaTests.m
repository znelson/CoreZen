//
//  MediaTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

// Fixtures in CoreZenTests/Resources, generated with Homebrew ffmpeg:
//   video.mp4: 2 s, 64x48 H.264 (keyframe every 0.5 s, with B-frames) + AAC audio
//     ffmpeg -f lavfi -i testsrc=size=64x48:rate=10:duration=2 -f lavfi -i sine=frequency=440:duration=2
//            -c:v libx264 -pix_fmt yuv420p -g 5 -c:a aac -b:a 32k -shortest -movflags +faststart video.mp4
//   audio.m4a: 2 s AAC audio, no video stream
//     ffmpeg -f lavfi -i sine=frequency=440:duration=2 -c:a aac -b:a 32k audio.m4a

static const NSTimeInterval kRenderTimeout = 10.0;

@interface MediaTests : XCTestCase

@property (nonatomic, strong) NSMutableArray<ZENMediaFile *> *mediaFiles;

@end

@implementation MediaTests

- (void)setUp {
	self.mediaFiles = [NSMutableArray new];
}

- (void)tearDown {
	for (ZENMediaFile *mediaFile in self.mediaFiles) {
		[mediaFile terminateMediaFile];
	}
	self.mediaFiles = nil;
}

#pragma mark - Helpers

- (ZENMediaFile *)mediaFileWithURL:(NSURL *)url {
	ZENMediaFile *mediaFile = [ZENMediaFile mediaFileWithURL:url];
	[self.mediaFiles addObject:mediaFile];
	return mediaFile;
}

- (ZENMediaFile *)mediaFileNamed:(NSString *)name {
	NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:name withExtension:nil];
	XCTAssertNotNil(url, @"Missing test resource %@", name);
	return [self mediaFileWithURL:url];
}

- (ZENMediaFile *)unreadableMediaFile {
	// A file with a video extension that libav can't open
	NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"CoreZenTests-unreadable.mp4"];
	NSError *error = nil;
	BOOL written = [@"not a video" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
	XCTAssertTrue(written, @"%@", error);
	return [self mediaFileWithURL:[NSURL fileURLWithPath:path]];
}

- (ZENRenderedFrame *)renderFrameAtPercentage:(double)percentage
								  ofMediaFile:(ZENMediaFile *)mediaFile {
	ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];
	XCTestExpectation *rendered = [self expectationWithDescription:@"frame rendered"];
	__block ZENRenderedFrame *result = nil;
	[renderer renderFrameAtPercentage:percentage width:32 height:32 completion:^(ZENRenderedFrame *frame) {
		result = frame;
		[rendered fulfill];
	}];
	[self waitForExpectations:@[rendered] timeout:kRenderTimeout];
	return result;
}

- (NSArray<ZENRenderedFrame *> *)renderFrames:(NSUInteger)count
								  ofMediaFile:(ZENMediaFile *)mediaFile {
	ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];
	XCTestExpectation *rendered = [self expectationWithDescription:@"frames rendered"];
	__block NSArray<ZENRenderedFrame *> *result = nil;
	[renderer renderFrames:count width:32 height:32 completion:^(NSArray<ZENRenderedFrame *> *frames) {
		result = frames;
		[rendered fulfill];
	}];
	[self waitForExpectations:@[rendered] timeout:kRenderTimeout];
	return result;
}

#pragma mark - Media info

- (void)testVideoFileInfo {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	XCTAssertEqualWithAccuracy(mediaFile.durationMicroseconds, 2000000, 100000);
	XCTAssertEqual(mediaFile.frameWidth, 64u);
	XCTAssertEqual(mediaFile.frameHeight, 48u);
	XCTAssertEqualObjects(mediaFile.videoCodecName, @"h264");
	XCTAssertEqualObjects(mediaFile.audioCodecName, @"aac");
}

- (void)testAudioOnlyFileInfo {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"audio.m4a"];
	XCTAssertEqualWithAccuracy(mediaFile.durationMicroseconds, 2000000, 100000);
	XCTAssertEqual(mediaFile.frameWidth, 0u);
	XCTAssertEqual(mediaFile.frameHeight, 0u);
	XCTAssertEqualObjects(mediaFile.videoCodecName, @"Unknown");
	XCTAssertEqualObjects(mediaFile.audioCodecName, @"aac");
}

- (void)testUnreadableFileInfo {
	ZENMediaFile *mediaFile = [self unreadableMediaFile];
	XCTAssertEqual(mediaFile.durationMicroseconds, 0u);
	XCTAssertEqual(mediaFile.frameWidth, 0u);
	XCTAssertEqual(mediaFile.frameHeight, 0u);
	XCTAssertEqualObjects(mediaFile.videoCodecName, @"Unknown");
	XCTAssertEqualObjects(mediaFile.audioCodecName, @"Unknown");
}

#pragma mark - Rendering

- (void)testRenderFrameAtPercentage {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	ZENRenderedFrame *frame = [self renderFrameAtPercentage:0.5 ofMediaFile:mediaFile];

	XCTAssertNotNil(frame.image);
	// Scaled to fit 32x32, keeping the 4:3 aspect ratio
	XCTAssertEqual(frame.image.size.width, 32);
	XCTAssertEqual(frame.image.size.height, 24);
	XCTAssertEqualWithAccuracy(frame.requestedSeconds, 1.0, 0.01);
	XCTAssertGreaterThanOrEqual(frame.actualSeconds, 0.0);
	XCTAssertLessThanOrEqual(frame.actualSeconds, 2.0);
}

- (void)testRenderFrameAtSeconds {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];
	XCTestExpectation *rendered = [self expectationWithDescription:@"frame rendered"];
	__block ZENRenderedFrame *result = nil;
	[renderer renderFrameAtSeconds:1.5 width:32 height:32 completion:^(ZENRenderedFrame *frame) {
		result = frame;
		[rendered fulfill];
	}];
	[self waitForExpectations:@[rendered] timeout:kRenderTimeout];

	XCTAssertNotNil(result.image);
	XCTAssertEqualWithAccuracy(result.requestedPercentage, 0.75, 0.01);
}

- (void)testRenderFramesAcrossVideo {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:5 ofMediaFile:mediaFile];

	// Frames are requested at 0%, 25%, 50%, 75% and 100%
	XCTAssertEqual(frames.count, 5u);
	for (ZENRenderedFrame *frame in frames) {
		XCTAssertNotNil(frame.image, @"No image at %.0f%%", frame.requestedPercentage * 100);
	}
}

- (void)testRenderFrameFromAudioOnlyFile {
	// There is no video stream to render, but the completion must still be called
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"audio.m4a"];
	ZENRenderedFrame *frame = [self renderFrameAtPercentage:0.5 ofMediaFile:mediaFile];
	XCTAssertNotNil(frame);
	XCTAssertNil(frame.image);
}

- (void)testRenderFrameFromUnreadableFile {
	ZENMediaFile *mediaFile = [self unreadableMediaFile];
	ZENRenderedFrame *frame = [self renderFrameAtPercentage:0.5 ofMediaFile:mediaFile];
	XCTAssertNotNil(frame);
	XCTAssertNil(frame.image);
}

- (void)testRenderFramesFromAudioOnlyFile {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"audio.m4a"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:5 ofMediaFile:mediaFile];
	XCTAssertNotNil(frames);
	XCTAssertEqual(frames.count, 0u);
}

- (void)testRenderSingleFrame {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:1 ofMediaFile:mediaFile];
	XCTAssertEqual(frames.count, 1u);
	XCTAssertNotNil(frames.firstObject.image);
}

- (void)testRenderSingleFrameFromAudioOnlyFile {
	// Like the multi-frame case, frames without an image are left out
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"audio.m4a"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:1 ofMediaFile:mediaFile];
	XCTAssertEqual(frames.count, 0u);
}

- (void)testRenderZeroFrames {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:0 ofMediaFile:mediaFile];
	XCTAssertEqual(frames.count, 0u);
}

- (void)testRenderFrameAfterTerminate {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];
	[mediaFile terminateMediaFile];
	[self.mediaFiles removeObject:mediaFile];

	XCTestExpectation *rendered = [self expectationWithDescription:@"frame rendered"];
	[renderer renderFrameAtPercentage:0.5 width:32 height:32 completion:^(ZENRenderedFrame *frame) {
		XCTAssertNil(frame.image);
		[rendered fulfill];
	}];
	[self waitForExpectations:@[rendered] timeout:kRenderTimeout];
}

- (void)testRenderFramesAfterTerminate {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"video.mp4"];
	ZENFrameRenderer *renderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];
	[mediaFile terminateMediaFile];
	[self.mediaFiles removeObject:mediaFile];

	XCTestExpectation *rendered = [self expectationWithDescription:@"frames rendered"];
	[renderer renderFrames:3 width:32 height:32 completion:^(NSArray<ZENRenderedFrame *> *frames) {
		XCTAssertEqual(frames.count, 0u);
		[rendered fulfill];
	}];
	[self waitForExpectations:@[rendered] timeout:kRenderTimeout];
}

@end
