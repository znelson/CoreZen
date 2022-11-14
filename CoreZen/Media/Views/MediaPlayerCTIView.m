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

@property (nonatomic, weak) IBOutlet NSSlider *slider;

- (IBAction)sliderChanged:(id)sender;

@property (nonatomic, weak) ZENMediaPlayer *player;
@property (nonatomic) BOOL scrubbing;
@property (nonatomic) BOOL previewing;

@end

@implementation ZENMediaPlayerCTIView

- (NSString *)archivedViewName {
	return @"ZENMediaPlayerCTIView";
}

- (void)initCommon {
	[super initCommon];
	
	self.scrubbing = NO;
	
	self.slider.minValue = 0.0;
	self.slider.maxValue = 100.0;
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	
	if (self.slider.trackingAreas.count > 0) {
		NSTrackingArea *area = self.slider.trackingAreas.firstObject;
		[self.slider removeTrackingArea:area];
	}
	
	NSRect rect = self.slider.bounds;
	NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp;
	NSDictionary *userData = nil;
	
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:options owner:self userInfo:userData];
	[self.slider addTrackingArea:area];
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
				if (!self.scrubbing) {
					NSNumber *positionPercent = [change objectForKey:NSKeyValueChangeNewKey];
					self.slider.doubleValue = positionPercent.doubleValue;
				}
			}
		}
	}
}

- (IBAction)sliderChanged:(id)sender {
	NSEvent *event = NSApplication.sharedApplication.currentEvent;
	NSEventType eventType = event.type;
	
	if (eventType == NSEventTypeLeftMouseDown || eventType == NSEventTypeLeftMouseDragged) {
		self.scrubbing = YES;
		
		double percentage = self.slider.doubleValue;
		[self.player seekAbsolutePercentage:percentage];
		
	} else if (eventType == NSEventTypeLeftMouseUp) {
		self.scrubbing = NO;
	}
}

- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	
	self.previewing = YES;
}

- (void)mouseMoved:(NSEvent *)event {
	[super mouseMoved:event];
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	
	self.previewing = NO;
}

@end
