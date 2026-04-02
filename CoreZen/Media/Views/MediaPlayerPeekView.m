//
//  MediaPlayerPeekView.m
//  CoreZen
//
//  Created by Zach Nelson on 11/10/22.
//

#import "MediaPlayerPeekView.h"

@interface ZENMediaPlayerPeekView ()

- (void)setupCommon;

@end

@implementation ZENMediaPlayerPeekView

- (void)setupCommon {
	self.wantsLayer = YES;
	self.layer.cornerRadius = 4;
	self.layer.masksToBounds = YES;
	self.layer.shadowRadius = 2;
	self.layer.borderWidth = 1;
	CGColorRef borderColor = CGColorCreateGenericGray(0.7, 0.6);
	self.layer.borderColor = borderColor;
	CGColorRelease(borderColor);
	
	self.imageView.wantsLayer = YES;
	self.imageView.layer.cornerRadius = 4;
	self.imageView.layer.masksToBounds = YES;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		[self setupCommon];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
	self = [super initWithCoder:coder];
	if (self) {
		[self setupCommon];
	}
	return self;
}

@end
