//
//  NSFileManager+CoreZen.h
//  CoreZen
//
//  Created by Zach Nelson on 9/27/18.
//

#import <Foundation/Foundation.h>

@interface NSFileManager (CoreZen)

- (NSURL *)zen_findOrCreateURLForDirectory:(NSSearchPathDirectory)searchPathDirectory
								  inDomain:(NSSearchPathDomainMask)domain
					   appendPathComponent:(NSString *)appendComponent
									create:(BOOL)create
									 error:(NSError **)outError;

- (NSURL *)zen_applicationSupportDirectory;

+ (NSString *)zen_executableName;

@end
