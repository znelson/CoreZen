//
//  MediaPlayerPeekView.m
//  CoreZen
//
//  Created by Zach Nelson on 11/10/22.
//

#import "MediaPlayerPeekView.h"

@interface ZENMediaPlayerPeekView ()

- (void)initCommon;

@end

@implementation ZENMediaPlayerPeekView

- (void)initCommon {
	self.wantsLayer = YES;
	self.layer.cornerRadius = 4;
	self.layer.masksToBounds = YES;
	self.layer.shadowRadius = 2;
	self.layer.borderWidth = 1;
	self.layer.borderColor = CGColorCreateGenericGray(0.7, 0.6);
	
	self.imageView.wantsLayer = YES;
	self.imageView.layer.cornerRadius = 4;
	self.imageView.layer.masksToBounds = YES;
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

@end
