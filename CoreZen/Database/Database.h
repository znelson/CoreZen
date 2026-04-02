//
//  Database.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

@class ZENResultSet;

@interface ZENDatabase : NSObject

- (BOOL)executeUpdate:(NSString *)sql, ...;
- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

- (ZENResultSet *)executeQuery:(NSString *)sql, ...;
- (ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

- (NSString *)lastErrorMessage;

@end
