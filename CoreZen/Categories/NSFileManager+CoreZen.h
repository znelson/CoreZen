//
//  NSFileManager+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 9/27/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (CoreZen)

// nil, with outError set, if the directory can't be found or created
- (nullable NSURL *)zen_findOrCreateURLForDirectory:(NSSearchPathDirectory)searchPathDirectory
										   inDomain:(NSSearchPathDomainMask)domain
								appendPathComponent:(nullable NSString *)appendComponent
											 create:(BOOL)create
											  error:(NSError *_Nullable *_Nullable)outError;

- (nullable NSURL *)zen_applicationSupportDirectory;

// nil if the main bundle doesn't name its executable
+ (nullable NSString *)zen_executableName;

@end

NS_ASSUME_NONNULL_END
