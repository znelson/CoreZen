//
//  FrameRenderer.m
//  CoreZen
//
//  Created by Zach Nelson on 11/8/22.
//

#import "FrameRenderer.h"
#import "FrameRenderController.h"

@interface ZENFrameRenderer ()

@property (nonatomic, strong) NSObject<ZENFrameRenderController> *frameRenderController;

@end

@implementation ZENFrameRenderer

- (instancetype)initWithController:(NSObject<ZENFrameRenderController> *)controller {
	self = [super init];
	if (self) {
		_frameRenderController = controller;
	}
	return self;
}

@end
