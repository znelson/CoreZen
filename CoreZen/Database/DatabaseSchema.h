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
/// past its largest identifier.
///
/// The update runs in a transaction, joining the caller's if one is open. If any
/// statement fails, the whole update rolls back, so it runs again the next time.
/// Then it raises the counter that ``ZENGetNextObjectIdentifier`` uses past the
/// largest identifier in any of the tables.
- (void)initializeDatabase:(ZENDatabase *)database;

@end

NS_ASSUME_NONNULL_END
