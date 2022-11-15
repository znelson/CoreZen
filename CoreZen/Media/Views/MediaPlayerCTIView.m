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
@property (nonatomic, strong) IBOutlet ZENMediaPlayerPeekView *peekView;

- (IBAction)sliderChanged:(id)sender;

@property (nonatomic, weak) ZENMediaPlayer *player;
@property (nonatomic) BOOL scrubbing;
@property (nonatomic) BOOL previewing;

@property (nonatomic, strong) ZENFrameRenderer *frameRenderer;
@property (nonatomic, strong) NSArray *previewFrames;

- (void)updateMediaFile:(NSURL *)url;

- (NSImage *)fetchPreview:(double)percentage;
- (void)updatePeekPreviewAt:(NSPoint)mousePoint;

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
	
	NSView *trackingView = self.slider.cell.controlView;
	
	if (trackingView.trackingAreas.count > 0) {
		NSTrackingArea *area = trackingView.trackingAreas.firstObject;
		[trackingView removeTrackingArea:area];
	}
	
	NSRect rect = self.slider.bounds;
	NSTrackingAreaOptions options = NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveInActiveApp;
	NSDictionary *userData = nil;
	
	NSTrackingArea *area = [[NSTrackingArea alloc] initWithRect:rect options:options owner:self userInfo:userData];
	[trackingView addTrackingArea:area];
}

- (void)viewDidMoveToWindow {
	[super viewDidMoveToWindow];
	NSWindow *window = self.window;
	if (window) {
		[window.contentView addSubview:self.peekView];
	}
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
	
	[self updatePeekPreviewAt:event.locationInWindow];
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
		
		NSUInteger width = 320;
		
		[self.frameRenderer renderFrames:101 width:width height:width completion:^(NSArray<ZENRenderedFrame *> *frames) {
			self.previewFrames = frames;
			
			NSLog(@"Rendered %lu frames", frames.count);
		}];
	}
}

- (NSImage *)fetchPreview:(double)percentage {
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

- (void)updatePeekPreviewAt:(NSPoint)mousePoint {
	NSImage *preview = nil;
	if (!self.scrubbing) {
		NSPoint sliderPoint = [self.slider convertPoint:mousePoint fromView:nil];
		double sliderWidth = self.slider.bounds.size.width;
		double percentage = sliderPoint.x / sliderWidth;
		
		preview = [self fetchPreview:percentage];
	}
	if (preview) {
		[self.peekView setFrameSize:preview.size];
		
		NSRect sliderRect = [self.slider convertRect:self.bounds toView:nil];
		
		// Centered over the mouse point
		double originX = mousePoint.x - (preview.size.width / 2.0);
		originX = fmax(sliderRect.origin.x, originX);
		originX = fmin(sliderRect.origin.x + sliderRect.size.width - preview.size.width, originX);
		
		// Above the slider
		double originY = sliderRect.origin.y + sliderRect.size.height;
		
		NSPoint peekOrigin = NSMakePoint(originX, originY);
		
		[self.peekView setFrameOrigin:peekOrigin];
		
		self.peekView.imageView.image = preview;
		[self.peekView setHidden:NO];
	} else {
		[self.peekView setHidden:YES];
	}
}

- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	self.previewing = YES;
	[self updatePeekPreviewAt:event.locationInWindow];
}

- (void)mouseMoved:(NSEvent *)event {
	[super mouseMoved:event];
	[self updatePeekPreviewAt:event.locationInWindow];
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	self.previewing = NO;
	[self updatePeekPreviewAt:event.locationInWindow];
}

@end
