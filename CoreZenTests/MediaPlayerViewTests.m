//
//  MediaPlayerViewTests.m
//  CoreZenTests
//

#import <XCTest/XCTest.h>

@import CoreZen;

#import "MediaPlayerView+Private.h"
#import "MPVRenderController.h"

static const NSTimeInterval kPlayerTimeout = 10.0;

@interface MediaPlayerViewTests : XCTestCase

@property (nonatomic, strong) NSMutableArray<ZENMediaPlayer *> *players;

@end

@implementation MediaPlayerViewTests

- (void)setUp {
	self.players = [NSMutableArray new];
}

- (void)tearDown {
	for (ZENMediaPlayer *player in self.players) {
		[player terminatePlayer];
	}
	self.players = nil;
}

#pragma mark - Helpers

// An offscreen view. mpv renders through its OpenGL context, so skip when
// there's no OpenGL (some virtual machines have none).
- (ZENMediaPlayerView *)newPlayerView {
	ZENMediaPlayerView *view = [[ZENMediaPlayerView alloc] initWithFrame:NSMakeRect(0, 0, 64, 48) pixelFormat:nil];
	XCTSkipUnless(view.openGLContext != nil, @"No OpenGL context available");
	return view;
}

- (ZENMediaPlayer *)newPlayer {
	ZENMediaPlayer *player = [ZENMediaPlayer new];
	[self.players addObject:player];
	return player;
}

// Plays the video fixture and waits for its position to move forward, which
// needs the view's render context to keep taking frames from mpv
- (void)playVideoAndExpectProgress:(ZENMediaPlayer *)player {
	NSURL *url = [[NSBundle bundleForClass:self.class] URLForResource:@"video" withExtension:@"mp4"];

	// mpv reports a position once the file has loaded
	[self keyValueObservingExpectationForObject:player keyPath:@"positionPercent" handler:nil];
	[player loadFileURL:url];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];

	[self keyValueObservingExpectationForObject:player
										keyPath:@"positionPercent"
										handler:^BOOL(id observed, NSDictionary *change) {
											return [observed positionPercent] > 25.0;
										}];
	[player startPlayback];
	[self waitForExpectationsWithTimeout:kPlayerTimeout handler:nil];
	[player pausePlayback];
}

#pragma mark - Attach and detach

- (void)testPlaybackAdvancesWhileAttached {
	ZENMediaPlayerView *view = [self newPlayerView];
	ZENMediaPlayer *player = [self newPlayer];
	[view attachPlayer:player];
	[self playVideoAndExpectProgress:player];
}

- (void)testPlaybackAdvancesAfterDetachAndReattach {
	ZENMediaPlayerView *view = [self newPlayerView];
	ZENMediaPlayer *first = [self newPlayer];
	[view attachPlayer:first];
	[self playVideoAndExpectProgress:first];
	[view detachPlayer];

	ZENMediaPlayer *second = [self newPlayer];
	[view attachPlayer:second];
	[self playVideoAndExpectProgress:second];
}

- (void)testAttachingAnotherPlayerDetachesTheFirst {
	ZENMediaPlayerView *view = [self newPlayerView];
	ZENMediaPlayer *first = [self newPlayer];
	ZENMediaPlayer *second = [self newPlayer];

	[view attachPlayer:first];
	[view attachPlayer:second];

	XCTAssertNil(first.playerView);
	XCTAssertEqual(second.playerView, view);
	XCTAssertEqual(view.player, second);
	[self playVideoAndExpectProgress:second];
}

- (void)testAttachingPlayerToAnotherViewDetachesItFromTheFirst {
	ZENMediaPlayerView *firstView = [self newPlayerView];
	ZENMediaPlayerView *secondView = [self newPlayerView];
	ZENMediaPlayer *player = [self newPlayer];

	[firstView attachPlayer:player];
	[secondView attachPlayer:player];

	XCTAssertNil(firstView.player);
	XCTAssertEqual(secondView.player, player);
	XCTAssertEqual(player.playerView, secondView);
	[self playVideoAndExpectProgress:player];
}

- (void)testDestroyingRenderContextThatWasNeverCreated {
	// Happens when creating the context failed and the player is then detached
	ZENMediaPlayerView *view = [self newPlayerView];
	[view.renderController destroyRenderContext];
}

@end
