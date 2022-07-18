//
//  PreferencesWindowController.m
//  CoreZen
//
//  Created by Zach Nelson on 7/11/22.
//

// The ZENPreferencesWindowController concept was adapted
// from CCNPreferencesWindowController at:
// https://github.com/phranck/CCNPreferencesWindowController
//
// This file is analogous to CCNPreferencesWindowController.m

//
//  Created by Frank Gregor on 16.01.15.
//  Copyright (c) 2015 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2014 Frank Gregor, <phranck@cocoanaut.com>
 http://cocoanaut.mit-license.org

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "PreferencesWindowController.h"
#import "PreferenceViewController.h"

#import <QuartzCore/QuartzCore.h>

#pragma mark - ZENPreferencesWindow

@interface ZENPreferencesWindow : NSWindow
@end

@implementation ZENPreferencesWindow

- (instancetype)init {
	NSWindowStyleMask windowStyle = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskUnifiedTitleAndToolbar;
	self = [super initWithContentRect:NSMakeRect(0, 0, 420, 240) styleMask:windowStyle backing:NSBackingStoreBuffered defer:YES];
	if (self) {
		[self center];
		self.frameAutosaveName = @"ZENPreferencesWindow";
		[self setFrameFromString:@"ZENPreferencesWindow"];
	}
	return self;
}

- (void)keyDown:(NSEvent *)event {
	if (event.keyCode == 53) {
		[self orderOut:nil];
		[self close];
		return;
	}
	[super keyDown:event];
}

@end

#pragma mark - ZENPreferencesWindowController

@interface ZENPreferencesWindowController () <NSToolbarDelegate>

@property (nonatomic, strong) NSMutableOrderedSet *viewControllers;
@property (nonatomic, strong) NSViewController<ZENPreferenceViewController> *activeViewController;

- (void)activateViewController:(NSViewController<ZENPreferenceViewController> *)viewController animate:(BOOL)animate;
- (NSViewController<ZENPreferenceViewController> *)viewControllerWithIdentifier:(NSString *)identifier;
- (void)toolbarItemAction:(NSToolbarItem *)toolbarItem;

@end

@implementation ZENPreferencesWindowController

- (instancetype)init {
	self = [super init];
	if (self) {
		self.viewControllers = [NSMutableOrderedSet new];
		self.activeViewController = nil;
		
		self.window = [ZENPreferencesWindow new];
		self.window.titlebarAppearsTransparent = NO;
	}
	return self;
}

- (void)activateViewController:(NSViewController<ZENPreferenceViewController> *)viewController animate:(BOOL)animate {
	NSRect currentWindowFrame = self.window.frame;
	NSRect viewControllerFrame = viewController.view.frame;
	NSRect frameRectForContentRect = [self.window frameRectForContentRect:viewControllerFrame];

	CGFloat deltaX = NSWidth(currentWindowFrame) - NSWidth(frameRectForContentRect);
	CGFloat deltaY = NSHeight(currentWindowFrame) - NSHeight(frameRectForContentRect);
	NSRect newWindowFrame = NSMakeRect(NSMinX(currentWindowFrame) + (deltaX / 2.0),
									   NSMinY(currentWindowFrame) + deltaY,
									   NSWidth(frameRectForContentRect),
									   NSHeight(frameRectForContentRect));

	self.window.title = viewController.preferenceDisplayName;

	NSView *contentView = viewController.view;
	contentView.alphaValue = 0.0;

	NSView *view = [[NSView alloc] initWithFrame:contentView.frame];
	[view addSubview:contentView];
	self.window.contentView = view;

	[NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
		context.duration = (animate ? 0.25 : 0);
		context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		[self.window.animator setFrame:newWindowFrame display:YES];
		[contentView.animator setAlphaValue:1.0];
	} completionHandler:^{
		self.activeViewController = viewController;
	}];
}

- (NSViewController<ZENPreferenceViewController> *)viewControllerWithIdentifier:(NSString *)identifier {
	for (NSViewController<ZENPreferenceViewController> *viewController in self.viewControllers) {
		if ([viewController.preferenceIdentifier isEqualToString:identifier]) {
			return viewController;
		}
	}
	return nil;
}

- (void)toolbarItemAction:(NSToolbarItem *)toolbarItem {
	if (![self.activeViewController.preferenceIdentifier isEqualToString:toolbarItem.itemIdentifier]) {
		NSViewController<ZENPreferenceViewController> *viewController = [self viewControllerWithIdentifier:toolbarItem.itemIdentifier];
		[self activateViewController:viewController animate:YES];
	}
}

#pragma mark - Public API

- (void)setPreferenceViewControllers:(NSArray *)viewControllers {
	for (NSViewController<ZENPreferenceViewController> *viewController in viewControllers) {
		NSAssert([viewController conformsToProtocol:@protocol(ZENPreferenceViewController)], @"ERROR: The viewController [%@] must conform to protocol <ZENPreferenceViewController>", [viewController class]);
		[self.viewControllers addObject:viewController];
	}
}

- (void)showPreferencesWindow {
	[self showWindow:self];
	[self.window makeKeyAndOrderFront:self];
	[self activateViewController:self.viewControllers.firstObject animate:NO];
	
	NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"ZENPreferencesWindowController"];
	toolbar.allowsUserCustomization = NO;
	toolbar.autosavesConfiguration = YES;
	toolbar.showsBaselineSeparator = YES;
	toolbar.delegate = self;
	toolbar.selectedItemIdentifier = self.activeViewController.preferenceIdentifier;
	
	self.window.toolbar = toolbar;
}

- (void)dismissPreferencesWindow {
	[self close];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarSelectableItemIdentifiers:(NSToolbar *)toolbar {
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
	NSMutableArray *identifiers = [NSMutableArray new];
	
	[self.viewControllers enumerateObjectsUsingBlock:^(NSViewController<ZENPreferenceViewController> *viewController, NSUInteger idx, BOOL *stop) {
		[identifiers addObject:viewController.preferenceIdentifier];
	}];
	
	return identifiers;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
	NSViewController<ZENPreferenceViewController> *viewController = [self viewControllerWithIdentifier:itemIdentifier];
	
	NSToolbarItem *toolbarItem = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	toolbarItem.label = viewController.preferenceDisplayName;
	toolbarItem.paletteLabel = viewController.preferenceDisplayName;
	toolbarItem.image = viewController.preferenceIcon;
	toolbarItem.target = self;
	toolbarItem.action = @selector(toolbarItemAction:);
	
	if ([viewController respondsToSelector:@selector(preferenceToolTip)]) {
		toolbarItem.toolTip = viewController.preferenceToolTip;
	}
	
	return toolbarItem;
}

@end
