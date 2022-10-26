//
//  MediaPlayerControlsView.m
//  CoreZen
//
//  Created by Zach Nelson on 8/10/22.
//

#import "MediaPlayerControlsView.h"
#import "MediaPlayer.h"

static void* ObserverContext = &ObserverContext;

@interface ZENMediaPlayerControlsView ()

@property (nonatomic, weak) IBOutlet NSView *rootView;

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

- (void)initCommon;

- (IBAction)buttonClicked:(id)sender;

@end

@implementation ZENMediaPlayerControlsView

- (void)initCommon {
	NSBundle *bundle = [NSBundle bundleForClass:ZENMediaPlayerControlsView.class];
	NSNib *nib = [[NSNib alloc] initWithNibNamed:@"ZENMediaPlayerControlsView" bundle:bundle];
	if ([nib instantiateWithOwner:self topLevelObjects:nil]) {
		NSView *nibView = self.rootView;
		[self addSubview:nibView];
		
		NSMutableArray *constraints = [NSMutableArray new];
		
		NSLayoutAttribute attrs[4] = { NSLayoutAttributeLeft, NSLayoutAttributeTop, NSLayoutAttributeHeight, NSLayoutAttributeWidth };
		
		for (int i = 0; i < 4; ++i) {
			NSLayoutAttribute attr = attrs[i];
			NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:nibView attribute:attr relatedBy:NSLayoutRelationEqual toItem:self attribute:attr multiplier:1 constant:0];
			[constraints addObject:constraint];
		}
		
		[self addConstraints:constraints];
	}
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self initCommon];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self initCommon];
	}
	return self;
}

- (IBAction)buttonClicked:(id)sender {
	if (self.player) {
		if (sender == self.prevButton1) {
			[self.player frameStepBack];
		} else if (sender == self.prevButton2) {
		} else if (sender == self.prevButton3) {
		} else if (sender == self.prevButton4) {
		} else if (sender == self.playPauseButton) {
			if (self.player.paused) {
				[self.player startPlayback];
			} else {
				[self.player pausePlayback];
			}
		} else if (sender == self.nextButton1) {
			[self.player frameStepForward];
		} else if (sender == self.nextButton2) {
		} else if (sender == self.nextButton3) {
		} else if (sender == self.nextButton4) {
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
