//
//  MediaPlayerCTIView.m
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import "MediaPlayerCTIView.h"
#import "MediaPlayer.h"

static void* ObserverContext = &ObserverContext;

@interface ZENMediaPlayerCTIView ()

@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressBar;

@property (nonatomic, weak) ZENMediaPlayer *player;

@end

@implementation ZENMediaPlayerCTIView

- (NSString *)archivedViewName {
	return @"ZENMediaPlayerCTIView";
}

- (void)initCommon {
	[super initCommon];
	
	self.progressBar.minValue = 0.0;
	self.progressBar.maxValue = 100.0;
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	self.player = player;
	
	if (player) {
		[player addObserver:self
				 forKeyPath:@"positionPercent"
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
			if ([keyPath isEqualToString:@"positionPercent"]) {
				NSNumber *positionPercent = [change objectForKey:NSKeyValueChangeNewKey];
				self.progressBar.doubleValue = positionPercent.doubleValue;
			}
		}
	}
}

@end
