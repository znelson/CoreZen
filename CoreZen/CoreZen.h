//
//  CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 7/18/22.
//

#import <Foundation/Foundation.h>

//! Project version number for CoreZen.
FOUNDATION_EXPORT double CoreZenVersionNumber;

//! Project version string for CoreZen.
FOUNDATION_EXPORT const unsigned char CoreZenVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <CoreZen/PublicHeader.h>

#pragma mark - Categories
#import <CoreZen/NSFileManager+CoreZen.h>
#import <CoreZen/NSURL+CoreZen.h>
#import <CoreZen/NSNumber+CoreZen.h>

#pragma mark - Identifiers
#import <CoreZen/Identifier.h>
#import <CoreZen/Identifiable.h>
#import <CoreZen/ObjectIdentifier.h>

#pragma mark - Preferences
#import <CoreZen/PreferencesWindowController.h>
#import <CoreZen/PreferenceViewController.h>

#pragma mark - Cache
#import <CoreZen/ObjectCache.h>
