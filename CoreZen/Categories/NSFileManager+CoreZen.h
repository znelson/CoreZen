//
//  NSFileManager+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 9/27/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (CoreZen)

/// Finds a standard folder, such as Application Support, with a path component
/// appended if one is given, and creates it if asked to.
///
/// It returns nil, with the error set, if the folder can't be found or created.
- (nullable NSURL *)zen_findOrCreateURLForDirectory:(NSSearchPathDirectory)searchPathDirectory
										   inDomain:(NSSearchPathDomainMask)domain
								appendPathComponent:(nullable NSString *)appendComponent
											 create:(BOOL)create
											  error:(NSError *_Nullable *_Nullable)outError;

/// The app's own folder in the user's Application Support folder, named after
/// its executable, which this creates if there's none.
///
/// It returns nil, and logs an error, if the folder can't be found or created.
- (nullable NSURL *)zen_applicationSupportDirectory;

/// The name of the main bundle's executable, or nil if the bundle doesn't name
/// it.
+ (nullable NSString *)zen_executableName;

@end

NS_ASSUME_NONNULL_END
