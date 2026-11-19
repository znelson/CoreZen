//
//  Database.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

@class ZENResultSet;

NS_ASSUME_NONNULL_BEGIN

// Why database work didn't save its changes. Each error's description gives the
// details, including SQLite's message when there is one.
extern NSErrorDomain const ZENDatabaseErrorDomain;

typedef NS_ERROR_ENUM(ZENDatabaseErrorDomain, ZENDatabaseErrorCode){
	// A statement failed, so its transaction rolled back
	ZENDatabaseErrorStatementFailed = 1,
	// The transaction's block canceled it, so it rolled back
	ZENDatabaseErrorTransactionCanceled = 2,
	// SQLite couldn't commit the transaction, so it rolled back
	ZENDatabaseErrorCommitFailed = 3,
	// The database couldn't be opened
	ZENDatabaseErrorNotOpen = 4,
	// A table reported that it couldn't write, though no statement failed
	ZENDatabaseErrorWriteFailed = 5,
};

@interface ZENDatabase : NSObject

- (BOOL)executeUpdate:(NSString *)sql, ...;
- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

// nil if the query fails, which in a transaction makes it roll back
- (nullable ZENResultSet *)executeQuery:(NSString *)sql, ...;
- (nullable ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

- (NSString *)lastErrorMessage;

// In a transaction block: roll back the transaction's changes when the block
// returns, instead of committing them. Statements the block runs after this
// still run, and roll back too. A transaction also rolls back on its own when
// one of its statements fails.
- (void)cancelTransaction;

@end

NS_ASSUME_NONNULL_END
