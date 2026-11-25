//
//  DatabaseSchema.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;

NS_ASSUME_NONNULL_BEGIN

/// Brings a database up to the latest version of its tables' schemas.
///
/// The version is one number for the whole database, which SQLite keeps as its
/// `user_version`. To update it, the schema asks every table to make its change
/// for the next version, with ``ZENDatabaseTable/updateSchema:version:``, and
/// repeats until no table has a change for the next version.
@interface ZENDatabaseSchema : NSObject

/// Makes a schema for tables, given as classes that conform to
/// ``ZENDatabaseTable``.
+ (instancetype)schemaWithTableClasses:(NSArray *)tables;

/// Updates a database to the latest version, then moves the identifier counter
/// past its largest identifier, and says whether the update worked.
///
/// The update runs in a transaction of its own, or joins the caller's if one is
/// open. If any statement in it fails, or its commit does, the whole update rolls
/// back, so the database keeps the version it had, and the update runs again the
/// next time. Joined to the caller's transaction, the update saves only when that
/// transaction commits, and it fails if that transaction is already set to roll
/// back.
///
/// It returns YES once the database is at the latest version, including when it
/// already was. It returns NO, with the error set, if the update failed. The
/// error is in ``ZENDatabaseErrorDomain``, and for a failed statement, its
/// description has SQLite's message. The error pointer may be NULL.
///
/// Either way, it then raises the counter that ``ZENGetNextObjectIdentifier``
/// uses past the largest identifier in any of the tables, which can hold rows
/// even when the update fails.
- (BOOL)initializeDatabase:(ZENDatabase *)database error:(NSError *_Nullable *_Nullable)outError;

/// Updates a database to the latest version, then moves the identifier counter
/// past its largest identifier, without saying whether the update worked.
///
/// It does what ``initializeDatabase:error:`` does, but a caller can't tell that
/// the update failed, and goes on to use tables the update didn't change.
- (void)initializeDatabase:(ZENDatabase *)database
	__attribute__((deprecated("Use initializeDatabase:error:, which says whether the update worked")));

@end

NS_ASSUME_NONNULL_END
