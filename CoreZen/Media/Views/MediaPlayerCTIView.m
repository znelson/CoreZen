//
//  MediaPlayerCTIView.m
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import "MediaPlayerCTIView.h"
#import "MediaPlayer.h"
#import "MediaPlayerPeekView.h"
#import "MediaFile.h"
#import "FrameRenderer.h"

static void* ObserverContext = &ObserverContext;

@interface ZENMediaPlayerCTIView ()

@property (nonatomic, weak) IBOutlet NSSlider *slider;
@property (nonatomic, weak) IBOutlet ZENMediaPlayerPeekView *peekView;

- (IBAction)sliderChanged:(id)sender;

@property (nonatomic, weak) ZENMediaPlayer *player;
@property (nonatomic) BOOL scrubbing;
@property (nonatomic) BOOL previewing;

@property (nonatomic, strong) ZENFrameRenderer *frameRenderer;
@property (nonatomic, strong) NSArray *previewFrames;

- (void)updateMediaFile:(NSURL *)url;

- (NSImage *)fetchPreview:(double)percentage;
- (double)windowPointToSliderPercentage:(NSPoint)point;
- (void)updatePeekPreview:(NSImage *)preview;

@end

@implementation ZENMediaPlayerCTIView

- (NSString *)archivedViewName {
	return @"ZENMediaPlayerCTIView";
}

- (void)initCommon {
	[super initCommon];
	
	self.scrubbing = NO;
	self.previewing = NO;
	
	self.slider.minValue = 0.0;
	self.slider.maxValue = 100.0;
}

- (void)updateTrackingAreas {
	[super updateTrackingAreas];
	
	if (self.slider.cell.controlView.trackingAreas.count > 0) {
		NSTrackingArea *area = self.slider.trackingAreas.firstObject;
		[self.slider.cell.controlView removeTrackingArea:area];
	}
	
	NSRect rect = self.slider.bounds;
	NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp;
	NSDictionary *userData = nil;
	
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:options owner:self userInfo:userData];
	[self.slider.cell.controlView addTrackingArea:area];
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	self.player = player;
	
	if (player) {
		[player addObserver:self
				 forKeyPath:@"positionPercent"
					options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
					context:ObserverContext];
		
		[player addObserver:self
				 forKeyPath:@"fileURL"
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
			} else if ([keyPath isEqualToString:@"fileURL"]) {
				[self updateMediaFile:self.player.fileURL];
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

- (void)updateMediaFile:(NSURL *)url {
	NSLog(@"MediaPlayerCTIView fileURL changed: %@", url);
	
	if (self.frameRenderer) {
		[self.frameRenderer.mediaFile terminateMediaFile];
		self.previewFrames = nil;
	}
	
	if (url) {
		ZENMediaFile *mediaFile = [ZENMediaFile mediaFileWithURL:url];
		self.frameRenderer = mediaFile.frameRenderer;
		
		NSUInteger width = 640;
		
		[self.frameRenderer renderFrames:5 width:width height:width completion:^(NSArray<ZENRenderedFrame *> *frames) {
			self.previewFrames = frames;
			
			NSLog(@"Rendered %lu frames", frames.count);
			for (ZENRenderedFrame *frame in frames) {
				NSLog(@"Rendered frame at %f %%", frame.actualPercentage);
			}
		}];
	}
}

- (NSImage *)fetchPreview:(double)percentage {
	NSLog(@"fetchPreview: %f %%", percentage * 100);
	
	NSImage *preview = nil;
	
	if (self.previewFrames) {
		double minDistance = 1.0;
		for (ZENRenderedFrame *frame in self.previewFrames) {
			double distance = fabs(frame.actualPercentage - percentage);
			if (distance < minDistance) {
				preview = frame.image;
				minDistance = distance;
			}
		}
	}
	
	return preview;
}

- (double)windowPointToSliderPercentage:(NSPoint)point {
	NSPoint sliderPoint = [self.slider convertPoint:point fromView:nil];
	double sliderWidth = self.slider.bounds.size.width;
	double percentage = sliderPoint.x / sliderWidth;
	return percentage;
}

- (void)updatePeekPreview:(NSImage *)preview {
	ZENMediaPlayerPeekView *peekView = self.peekView;
	if (preview) {
		peekView.imageView.image = preview;
		[peekView setHidden:NO];
		peekView.bounds = NSMakeRect(0.0, 0.0, preview.size.width, preview.size.height);
	} else {
		[peekView setHidden:YES];
	}
}

- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	
	self.previewing = YES;
	
	double percentage = [self windowPointToSliderPercentage:event.locationInWindow];
	NSImage *preview = [self fetchPreview:percentage];
	
	[self updatePeekPreview:preview];
}

- (void)mouseMoved:(NSEvent *)event {
	[super mouseMoved:event];
	
	double percentage = [self windowPointToSliderPercentage:event.locationInWindow];
	NSImage *preview = [self fetchPreview:percentage];
	
	[self updatePeekPreview:preview];
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	
	NSPoint sliderPoint = [self.slider convertPoint:event.locationInWindow fromView:nil];
	NSLog(@"mouseExited: %f x %f", sliderPoint.x, sliderPoint.y);
	
	self.previewing = NO;
	
	if (!self.peekView.isHidden) {
		[self.peekView setHidden:YES];
	}
}

@end
