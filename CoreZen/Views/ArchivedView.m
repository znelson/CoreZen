//
//  ArchivedView.m
//  CoreZen
//
//  Created by Zach Nelson on 10/26/22.
//

#import "ArchivedView.h"

#import <CoreZen/NSView+CoreZen.h>

@implementation ZENArchivedView

- (NSString *)archivedViewName {
	NSString *errorReason = @"ZENArchivedView: -archivedViewName implementation must be provided by derived class";
	@throw [NSException exceptionWithName:NSInternalInconsistencyException reason:errorReason userInfo:nil];
}

- (void)initCommon {
	NSBundle *bundle = [NSBundle bundleForClass:ZENArchivedView.class];
	NSNib *nib = [[NSNib alloc] initWithNibNamed:self.archivedViewName bundle:bundle];
	if ([nib instantiateWithOwner:self topLevelObjects:nil]) {
		NSView *nibView = self.rootView;
		[self addSubview:nibView];
		
		[self zen_addConstraintsForEqualSizes:nibView];
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

@end
