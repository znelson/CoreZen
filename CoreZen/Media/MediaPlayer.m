//
//  MediaPlayer.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MediaPlayer+Private.h"
#import "MediaPlayerView+Private.h"
#import "MPVPlayerController.h"

@implementation ZENMediaPlayer

- (instancetype)initWithFileURL:(NSURL*)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_playerController = [[ZENMPVPlayerController alloc] initWithPlayer:self];
	}
	return self;
}

- (void)attachPlayerView:(ZENMediaPlayerView *)view {
	self.playerView = view;
	self.playerView.player = self;
}

- (void)startPlayback {
	if (self.playerView) {
		[self.playerController startPlayback];
	}
}

- (void)pausePlayback {
	if (self.playerView) {
		[self.playerController pausePlayback];
	}
}

@end
