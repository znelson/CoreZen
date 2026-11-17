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

static void *ObserverContext = &ObserverContext;

@interface ZENMediaPlayerCTIView ()

@property (nonatomic, weak) IBOutlet NSSlider *slider;
@property (nonatomic, strong) IBOutlet ZENMediaPlayerPeekView *peekView;

- (IBAction)sliderChanged:(id)sender;

@property (nonatomic, weak) ZENMediaPlayer *player;
@property (nonatomic) BOOL scrubbing;
@property (nonatomic) BOOL previewing;

// Main thread only
@property (nonatomic, strong) ZENFrameRenderer *frameRenderer;
@property (nonatomic, strong) NSArray *previewFrames;

// Counts updateMediaFile: calls, so work still in flight for an earlier file
// can tell it's stale. Main thread only.
@property (nonatomic) NSUInteger mediaFileGeneration;

- (void)updateMediaFile:(NSURL *)url;
- (void)renderPreviewsWithRenderer:(ZENFrameRenderer *)frameRenderer
						generation:(NSUInteger)generation;

- (NSImage *)fetchPreview:(double)percentage;
- (void)updatePeekPreviewAt:(NSPoint)mousePoint;

@end

@implementation ZENMediaPlayerCTIView

- (NSString *)archivedViewName {
	return @"ZENMediaPlayerCTIView";
}

- (void)setupCommon {
	[super setupCommon];

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

- (void)removePlayerObservers {
	if (self.player) {
		[self.player removeObserver:self forKeyPath:@"positionPercent" context:ObserverContext];
		[self.player removeObserver:self forKeyPath:@"fileURL" context:ObserverContext];
	}
}

- (void)dealloc {
	[self removePlayerObservers];
	[self.frameRenderer.mediaFile terminateMediaFile];
}

- (void)attachPlayer:(ZENMediaPlayer *)player {
	[self removePlayerObservers];
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
						change:(NSDictionary<NSKeyValueChangeKey, id> *)change
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

	// Anything still opening or rendering for an earlier file is stale from here on
	NSUInteger generation = ++self.mediaFileGeneration;

	[self.frameRenderer.mediaFile terminateMediaFile];
	self.frameRenderer = nil;
	self.previewFrames = nil;

	if (!url) {
		return;
	}

	// Opening a media file reads it from disk, so keep that off the main thread
	__weak ZENMediaPlayerCTIView *weakSelf = self;
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		ZENMediaFile *mediaFile = [ZENMediaFile mediaFileWithURL:url];
		ZENFrameRenderer *frameRenderer = [ZENFrameRenderer frameRendererWithMediaFile:mediaFile];

		dispatch_async(dispatch_get_main_queue(), ^{
			ZENMediaPlayerCTIView *strongSelf = weakSelf;
			if (strongSelf && strongSelf.mediaFileGeneration == generation) {
				[strongSelf renderPreviewsWithRenderer:frameRenderer generation:generation];
			} else {
				// The view moved on to another file, or went away, while this one opened
				[mediaFile terminateMediaFile];
			}
		});
	});
}

- (void)renderPreviewsWithRenderer:(ZENFrameRenderer *)frameRenderer
						generation:(NSUInteger)generation {
	self.frameRenderer = frameRenderer;

	NSUInteger width = 320;

	__weak ZENMediaPlayerCTIView *weakSelf = self;
	[frameRenderer renderFrames:101 width:width height:width completion:^(NSArray<ZENRenderedFrame *> *frames) {
		// Rendering completes on a background queue, but previewFrames is read
		// on the main thread as the mouse moves
		dispatch_async(dispatch_get_main_queue(), ^{
			ZENMediaPlayerCTIView *strongSelf = weakSelf;
			if (strongSelf.mediaFileGeneration == generation) {
				strongSelf.previewFrames = frames;
				NSLog(@"Rendered %lu frames", frames.count);
			}
		});
	}];
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
	if (self.previewing && !self.scrubbing) {
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
