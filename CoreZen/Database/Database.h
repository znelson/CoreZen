//
//  Database.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

@class ZENResultSet;

NS_ASSUME_NONNULL_BEGIN

/// The domain of the errors that say why database work didn't save its changes.
///
/// Each error's description gives the details, including SQLite's message when
/// there is one.
extern NSErrorDomain const ZENDatabaseErrorDomain;

/// Why database work didn't save its changes.
typedef NS_ERROR_ENUM(ZENDatabaseErrorDomain, ZENDatabaseErrorCode){
	/// A statement failed, so its transaction rolled back.
	ZENDatabaseErrorStatementFailed = 1,
	/// The transaction's block canceled it, so it rolled back.
	ZENDatabaseErrorTransactionCanceled = 2,
	/// SQLite couldn't commit the transaction, so it rolled back.
	ZENDatabaseErrorCommitFailed = 3,
	/// The database couldn't be opened.
	ZENDatabaseErrorNotOpen = 4,
	/// A table reported that it couldn't write, though no statement failed.
	ZENDatabaseErrorWriteFailed = 5,
};

/// A connection to a database, for running statements in the blocks a
/// ``ZENDatabaseQueue`` runs.
///
/// A statement's `?` placeholders take Objective-C objects, such as `NSString`,
/// `NSNumber`, `NSData`, `NSDate` (stored as seconds since 1970) or `NSNull`
/// for NULL. Use a database only in the block it was passed to.
@interface ZENDatabase : NSObject

/// Runs a statement that returns no rows, such as an `INSERT`, with an object
/// for each `?` in it.
///
/// It returns NO if the statement fails, which in a transaction makes the
/// transaction roll back.
- (BOOL)executeUpdate:(NSString *)sql, ...;

/// Runs a statement that returns no rows, with the objects in an array for its
/// `?` placeholders.
///
/// It returns NO if the statement fails, which in a transaction makes the
/// transaction roll back.
- (BOOL)executeUpdate:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

/// Runs a query, with an object for each `?` in it.
///
/// It returns nil if the query fails, which in a transaction makes the
/// transaction roll back.
- (nullable ZENResultSet *)executeQuery:(NSString *)sql, ...;

/// Runs a query, with the objects in an array for its `?` placeholders.
///
/// It returns nil if the query fails, which in a transaction makes the
/// transaction roll back.
- (nullable ZENResultSet *)executeQuery:(NSString *)sql withArgumentsInArray:(NSArray *)arguments;

/// SQLite's message about the most recent statement, which says why it failed.
- (NSString *)lastErrorMessage;

/// Rolls back the transaction when its block returns, instead of committing it.
///
/// Call it in a transaction block. Statements the block runs after this still
/// run, and roll back too. A transaction also rolls back on its own when one of
/// its statements fails.
- (void)cancelTransaction;

@end

NS_ASSUME_NONNULL_END
