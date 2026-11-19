//
//  DatabaseTable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;
@class ZENResultSet;
@class ZENDataTransferObject;

#import <CoreZen/Identifier.h>

NS_ASSUME_NONNULL_BEGIN

/// A class for one table, which creates and migrates the table, and reads and
/// writes its rows as DTOs.
///
/// A repository makes one instance of its table class, with `new`, and calls it
/// on its database queue. Every table needs an integer column named
/// `identifier`, whose largest value ``ZENDatabaseSchema`` reads. The rows a
/// repository reads, from ``allRows:``, ``rowByIdentifier:database:`` and its
/// query fetches, must have the identifier as their first column: the repository
/// reads it to find an object it already has, without making a DTO.
@protocol ZENDatabaseTable

#pragma mark - Metadata

/// The table's name in SQL.
+ (NSString *)tableName;

/// Makes the table's change for a schema version, if it has one.
///
/// ``ZENDatabaseSchema`` calls this for every table with the version after the
/// database's current one, then the next, for as long as at least one table has
/// a change. Version numbers are shared by every table in a schema. Make the
/// change and return YES if the table has one for this version, or else return
/// NO. The statements run in the schema update's transaction, so if one fails,
/// the whole update rolls back.
+ (BOOL)updateSchema:(ZENDatabase *)database
			 version:(NSUInteger)version;

#pragma mark - Create

/// Inserts a row with a DTO's values.
///
/// It returns NO if it couldn't. In a repository's write, that rolls back the
/// transaction.
- (BOOL)insertDTO:(ZENDataTransferObject *)dto
		 database:(ZENDatabase *)database;

#pragma mark - Update

/// Updates the row with a DTO's identifier to the DTO's values.
///
/// It returns NO if it couldn't. In a repository's write, that rolls back the
/// transaction.
- (BOOL)updateDTO:(ZENDataTransferObject *)dto
		 database:(ZENDatabase *)database;

#pragma mark - Delete

/// Deletes the row with an identifier.
///
/// It returns NO if it couldn't. In a repository's write, that rolls back the
/// transaction.
- (BOOL)deleteByIdentifier:(ZENIdentifier)identifier
				  database:(ZENDatabase *)database;

#pragma mark - Read

/// Makes a DTO from the current row of a result set.
- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row;

/// Every row, with the identifier as the first column.
///
/// It returns nil if the query fails.
- (nullable ZENResultSet *)allRows:(ZENDatabase *)database;

/// The row with an identifier, with the identifier as the first column.
///
/// It returns nil if the query fails, and a result set with no rows if there's
/// no such row.
- (nullable ZENResultSet *)rowByIdentifier:(ZENIdentifier)identifier
								  database:(ZENDatabase *)database;

#pragma mark - Count

/// The number of rows.
- (NSUInteger)countAllRows:(ZENDatabase *)database;

@end

NS_ASSUME_NONNULL_END
