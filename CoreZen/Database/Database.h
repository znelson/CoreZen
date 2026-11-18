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

// In a transaction block: roll back the transaction's changes when the block
// returns, instead of committing them. Statements the block runs after this
// still run, and roll back too. A transaction also rolls back on its own when
// one of its statements fails.
- (void)cancelTransaction;

@end
