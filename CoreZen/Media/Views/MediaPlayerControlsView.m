//
//  MediaPlayerControlsView.m
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import "MediaPlayerControlsView.h"
#import "MediaPlayer.h"

static void* ObserverContext = &ObserverContext;

static const double kSeekBackSmallSeconds = -3.0;
static const double kSeekBackLargeSeconds = -10.0;
static const double kSeekForwardSmallSeconds = 6.0;
static const double kSeekForwardLargeSeconds = 15.0;

@interface ZENMediaPlayerControlsView ()

@property (nonatomic, weak) IBOutlet NSButton *prevButton1;
@property (nonatomic, weak) IBOutlet NSButton *prevButton2;
@property (nonatomic, weak) IBOutlet NSButton *prevButton3;
@property (nonatomic, weak) IBOutlet NSButton *prevButton4;

@property (nonatomic, weak) IBOutlet NSButton *playPauseButton;

@property (nonatomic, weak) IBOutlet NSButton *nextButton1;
@property (nonatomic, weak) IBOutlet NSButton *nextButton2;
@property (nonatomic, weak) IBOutlet NSButton *nextButton3;
@property (nonatomic, weak) IBOutlet NSButton *nextButton4;

@property (nonatomic, weak) ZENMediaPlayer *player;

- (IBAction)buttonClicked:(id)sender;

@end

@implementation ZENMediaPlayerControlsView

- (NSString *)archivedViewName {
	return @"ZENMediaPlayerControlsView";
}

- (IBAction)buttonClicked:(id)sender {
	if (self.player) {
		if (sender == self.prevButton1 || sender == self.nextButton1) {
			BOOL forward = (sender == self.nextButton1);
			[self.player stepOneFrame:forward];
		} else if (sender == self.prevButton2 || sender == self.nextButton2) {
			double seconds = (sender == self.nextButton2) ? kSeekForwardSmallSeconds : kSeekBackSmallSeconds;
			[self.player seekBySeconds:seconds];
		} else if (sender == self.prevButton3 || sender == self.nextButton3) {
			double seconds = (sender == self.nextButton3) ? kSeekForwardLargeSeconds : kSeekBackLargeSeconds;
			[self.player seekBySeconds:seconds];
		} else if (sender == self.prevButton4 || sender == self.nextButton4) {
		} else if (sender == self.playPauseButton) {
			if (self.player.paused) {
				[self.player startPlayback];
			} else {
				[self.player pausePlayback];
			}
		}
	}
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	self.player = player;
	
	if (player) {
		[player addObserver:self
				 forKeyPath:@"paused"
					options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
					context:ObserverContext];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary<NSKeyValueChangeKey,id> *)change
					   context:(void *)context {
	if (context == ObserverContext) {
		if (object == self.player) {
			if ([keyPath isEqualToString:@"paused"]) {
				NSNumber *paused = [change objectForKey:NSKeyValueChangeNewKey];
				NSString *imageName = paused.boolValue ? @"play.fill" : @"pause.fill";
				self.playPauseButton.image = [NSImage imageWithSystemSymbolName:imageName accessibilityDescription:nil];
			}
		}
	}
}

@end
