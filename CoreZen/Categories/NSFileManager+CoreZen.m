//
//  NSFileManager+CoreZen.m
//  CoreZen
//
//  Created by Zach Nelson on 9/27/18.
//

#import "NSFileManager+CoreZen.h"

@implementation NSFileManager (CoreZen)

- (NSURL *)zen_findOrCreateURLForDirectory:(NSSearchPathDirectory)searchPathDirectory
								  inDomain:(NSSearchPathDomainMask)domain
					   appendPathComponent:(NSString *)appendComponent
									create:(BOOL)create
									 error:(NSError **)outError {
	// Search for the directory
	NSURL *url = [NSFileManager.defaultManager URLForDirectory:searchPathDirectory inDomain:domain appropriateForURL:nil create:create error:outError];
	if (!url) {
		return nil;
	}
	
	// Append the extra path component
	if (appendComponent) {
		url = [url URLByAppendingPathComponent:appendComponent];
	}
	
	// Create the directory if necessary
	if (create && ![self createDirectoryAtURL:url withIntermediateDirectories:YES attributes:nil error:outError]) {
		return nil;
	}
	
	if (outError) {
		*outError = nil;
	}
	return url;
}

- (NSURL *)zen_applicationSupportDirectory {
	NSString *executableName = NSFileManager.zen_executableName;
	NSError *error;
	NSURL *url = [self zen_findOrCreateURLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appendPathComponent:executableName create:YES error:&error];
	if (!url) {
		NSLog(@"Unable to find or create application support directory: %@", error);
	}
	return url;
}

+ (NSString *)zen_executableName {
	return [NSBundle.mainBundle.infoDictionary objectForKey:(NSString*)kCFBundleExecutableKey];
}

@end
