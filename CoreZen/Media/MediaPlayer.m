//
//  MediaPlayer.m
//  CoreZen
//
//  Created by Zach Nelson on 7/23/22.
//

#import "MediaPlayer.h"
#import "MediaPlayerView.h"
#import "MPVController.h"

@interface ZENMediaPlayer ()

- (void)attachPlayerView:(ZENMediaPlayerView *)view;

@end

@implementation ZENMediaPlayer

- (instancetype)initWithFileURL:(NSURL*)url {
	self = [super init];
	if (self) {
		_fileURL = url;
		_playerController = [[ZENMPVController alloc] initWithPlayer:self];
	}
	return self;
}

- (void)attachPlayerView:(ZENMediaPlayerView *)view {
	self.playerView = view;
	self.playerView.player = self;
}

- (void)loadMediaFile {
	if (self.playerView) {
		[self.playerController loadMediaFile];
	}
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
