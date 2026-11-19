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
//   silent.mp4: video.mp4's video, no audio stream
//     ffmpeg -f lavfi -i testsrc=size=64x48:rate=10:duration=2 -c:v libx264 -pix_fmt yuv420p -g 5
//            -movflags +faststart silent.mp4
//   last-keyframe.mp4: 21 frames (2.1 s), keyframes exactly every 5 frames, so the
//   last frame (at 2 s) is a keyframe alone at the end. B-frames make the decoder
//   hold 2 frames back.
//     ffmpeg -f lavfi -i testsrc=size=64x48:rate=10 -frames:v 21 -c:v libx264 -pix_fmt yuv420p
//            -x264-params keyint=5:min-keyint=5:scenecut=0 -movflags +faststart last-keyframe.mp4
//   red-blue.mp4: 1 s, 64x32, left half red and right half blue, so a frame turned a
//   quarter turn shows which way it went
//     ffmpeg -f lavfi -i "color=c=red:s=32x32:r=10:d=1[l];color=c=blue:s=32x32:r=10:d=1[r];[l][r]hstack[out0]"
//            -c:v libx264 -pix_fmt yuv420p -g 5 -movflags +faststart red-blue.mp4
//   red-blue-rotated-90.mp4, -270, -180: red-blue.mp4 tagged to be shown turned that many
//   degrees clockwise, as phones tag portrait video with 90. -display_rotation counts
//   counterclockwise, so 90, 270 and 180 clockwise are -90, 90 and 180:
//     ffmpeg -display_rotation:v:0 -90 -i red-blue.mp4 -c copy -movflags +faststart red-blue-rotated-90.mp4

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
	XCTAssertTrue([mediaFile.videoCodecLongName containsString:@"H.264"], @"%@", mediaFile.videoCodecLongName);
	XCTAssertTrue([mediaFile.audioCodecLongName containsString:@"AAC"], @"%@", mediaFile.audioCodecLongName);
}

- (void)testSilentVideoFileInfo {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"silent.mp4"];
	XCTAssertEqualWithAccuracy(mediaFile.durationMicroseconds, 2000000, 100000);
	XCTAssertEqual(mediaFile.frameWidth, 64u);
	XCTAssertEqual(mediaFile.frameHeight, 48u);
	XCTAssertEqualObjects(mediaFile.videoCodecName, @"h264");
	XCTAssertNil(mediaFile.audioCodecName);
	XCTAssertNil(mediaFile.audioCodecLongName);
}

- (void)testAudioOnlyFileInfo {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"audio.m4a"];
	XCTAssertEqualWithAccuracy(mediaFile.durationMicroseconds, 2000000, 100000);
	XCTAssertEqual(mediaFile.frameWidth, 0u);
	XCTAssertEqual(mediaFile.frameHeight, 0u);
	XCTAssertNil(mediaFile.videoCodecName);
	XCTAssertNil(mediaFile.videoCodecLongName);
	XCTAssertEqualObjects(mediaFile.audioCodecName, @"aac");
}

- (void)testUnreadableFileInfo {
	ZENMediaFile *mediaFile = [self unreadableMediaFile];
	XCTAssertEqual(mediaFile.durationMicroseconds, 0u);
	XCTAssertEqual(mediaFile.frameWidth, 0u);
	XCTAssertEqual(mediaFile.frameHeight, 0u);
	XCTAssertNil(mediaFile.videoCodecName);
	XCTAssertNil(mediaFile.audioCodecName);
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

// The decoder holds frames back to put B-frames in order, so a keyframe with no
// frames after it only comes out once the decoder is told the file has ended
- (void)testRenderLastFrameWhenItIsAKeyframe {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"last-keyframe.mp4"];
	ZENRenderedFrame *frame = [self renderFrameAtPercentage:1.0 ofMediaFile:mediaFile];

	XCTAssertNotNil(frame.image);
	XCTAssertEqualWithAccuracy(frame.actualSeconds, 2.0, 0.05, @"Should render the last keyframe");
}

- (void)testRenderFramesAcrossVideoEndingInKeyframe {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"last-keyframe.mp4"];
	NSArray<ZENRenderedFrame *> *frames = [self renderFrames:5 ofMediaFile:mediaFile];
	XCTAssertEqual(frames.count, 5u, @"Every frame, including the one at 100%%, should render");
}

- (void)testRenderFrameAfterRenderingTheEnd {
	ZENMediaFile *mediaFile = [self mediaFileNamed:@"last-keyframe.mp4"];
	XCTAssertNotNil([self renderFrameAtPercentage:1.0 ofMediaFile:mediaFile].image);

	// Reaching the end leaves the file's decoder drained, so this render must reset it
	ZENRenderedFrame *frame = [self renderFrameAtPercentage:0.5 ofMediaFile:mediaFile];
	XCTAssertNotNil(frame.image);
	XCTAssertEqualWithAccuracy(frame.actualSeconds, 1.0, 0.05, @"Should render the keyframe at 1 s");
}

#pragma mark - Rotation

// "red" or "blue": the color of image at a point given as fractions of its width
// and height, from the top left
- (NSString *)colorOfImage:(NSImage *)image atX:(double)x y:(double)y {
	CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
	size_t width = CGImageGetWidth(cgImage);
	size_t height = CGImageGetHeight(cgImage);
	uint8_t *pixels = calloc(width * height, 4);
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * 4, colorSpace,
												 (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
	// A bitmap context keeps the image's top row first in memory
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
	size_t column = MIN((size_t)(x * width), width - 1);
	size_t row = MIN((size_t)(y * height), height - 1);
	uint8_t *pixel = pixels + 4 * (row * width + column);
	NSString *color = (pixel[0] > pixel[2]) ? @"red" : @"blue";
	CGContextRelease(context);
	CGColorSpaceRelease(colorSpace);
	free(pixels);
	return color;
}

- (void)testFrameSizeOfRotatedVideoIsAsShown {
	// Stored as 64x32 frames
	ZENMediaFile *unrotated = [self mediaFileNamed:@"red-blue.mp4"];
	XCTAssertEqual(unrotated.frameWidth, 64u);
	XCTAssertEqual(unrotated.frameHeight, 32u);
	XCTAssertEqual(unrotated.rotationDegrees, 0u);

	NSDictionary<NSString *, NSNumber *> *rotations = @{
		@"red-blue-rotated-90.mp4": @90,
		@"red-blue-rotated-270.mp4": @270,
	};
	[rotations enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *rotation, BOOL *stop) {
		ZENMediaFile *mediaFile = [self mediaFileNamed:name];
		XCTAssertEqual(mediaFile.rotationDegrees, rotation.unsignedIntegerValue, @"%@", name);
		XCTAssertEqual(mediaFile.frameWidth, 32u, @"%@ is shown a quarter turn round, so taller than wide", name);
		XCTAssertEqual(mediaFile.frameHeight, 64u, @"%@", name);
	}];

	ZENMediaFile *upsideDown = [self mediaFileNamed:@"red-blue-rotated-180.mp4"];
	XCTAssertEqual(upsideDown.rotationDegrees, 180u);
	XCTAssertEqual(upsideDown.frameWidth, 64u);
	XCTAssertEqual(upsideDown.frameHeight, 32u);

	// Files without video have no rotation
	XCTAssertEqual([self mediaFileNamed:@"audio.m4a"].rotationDegrees, 0u);
	XCTAssertEqual(self.unreadableMediaFile.rotationDegrees, 0u);
}

- (void)testRenderedFramesAreUpright {
	// name: the image's size fitted to 32x32, then where its two colors should be
	NSDictionary<NSString *, NSArray *> *expected = @{
		@"red-blue.mp4": @[@32, @16, @"red on the left"],
		@"red-blue-rotated-90.mp4": @[@16, @32, @"red on top"],
		@"red-blue-rotated-270.mp4": @[@16, @32, @"blue on top"],
		@"red-blue-rotated-180.mp4": @[@32, @16, @"blue on the left"],
	};
	[expected enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSArray *expectation, BOOL *stop) {
		ZENRenderedFrame *frame = [self renderFrameAtPercentage:0.5 ofMediaFile:[self mediaFileNamed:name]];
		XCTAssertNotNil(frame.image, @"%@", name);
		XCTAssertEqual(frame.image.size.width, [expectation[0] doubleValue], @"%@", name);
		XCTAssertEqual(frame.image.size.height, [expectation[1] doubleValue], @"%@", name);

		BOOL tall = frame.image.size.height > frame.image.size.width;
		NSString *first = tall ? [self colorOfImage:frame.image atX:0.5 y:0.25] : [self colorOfImage:frame.image atX:0.25 y:0.5];
		NSString *second = tall ? [self colorOfImage:frame.image atX:0.5 y:0.75] : [self colorOfImage:frame.image atX:0.75 y:0.5];
		NSString *found = [NSString stringWithFormat:@"%@ on %@", first, tall ? @"top" : @"the left"];
		XCTAssertEqualObjects(found, expectation[2], @"%@", name);
		XCTAssertNotEqualObjects(first, second, @"%@ should show both colors", name);
	}];
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
