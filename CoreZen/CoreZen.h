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

#pragma mark - Cache
#import <CoreZen/ObjectCache.h>

#pragma mark - Categories
#import <CoreZen/NSFileManager+CoreZen.h>
#import <CoreZen/NSURL+CoreZen.h>
#import <CoreZen/NSNumber+CoreZen.h>

#pragma mark - Database
#import <CoreZen/DatabaseQueue.h>
#import <CoreZen/DatabaseSchema.h>
#import <CoreZen/DatabaseTable.h>
#import <CoreZen/DataTransferObject.h>
@import FMDB;

#pragma mark - Domain
#import <CoreZen/DomainCommon.h>
#import <CoreZen/DomainObject.h>
#import <CoreZen/DomainCallbacks.h>
#import <CoreZen/ObjectRepository.h>

#pragma mark - Identifiers
#import <CoreZen/Identifier.h>
#import <CoreZen/Identifiable.h>
#import <CoreZen/ObjectIdentifier.h>

#pragma mark - Media
#import <CoreZen/MediaFile.h>
#import <CoreZen/MediaPlayer.h>
#import <CoreZen/MediaPlayerController.h>
#import <CoreZen/MediaPlayerView.h>
#import <CoreZen/MediaPlayerRenderController.h>

#pragma mark - Node
#import <CoreZen/Node.h>

#pragma mark - Preferences
#import <CoreZen/PreferencesWindowController.h>
#import <CoreZen/PreferenceViewController.h>

