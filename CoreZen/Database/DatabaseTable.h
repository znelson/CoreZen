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

@protocol ZENDatabaseTable

#pragma mark - Metadata

+ (NSString *)tableName;

+ (BOOL)updateSchema:(ZENDatabase *)database
			 version:(NSUInteger)version;

#pragma mark - Create

- (BOOL)insertDTO:(ZENDataTransferObject *)dto
		 database:(ZENDatabase *)database;

#pragma mark - Update

- (BOOL)updateDTO:(ZENDataTransferObject *)dto
		 database:(ZENDatabase *)database;

#pragma mark - Delete

- (BOOL)deleteByIdentifier:(ZENIdentifier)identifier
				  database:(ZENDatabase *)database;

#pragma mark - Read

// A repository makes its objects from the rows of allRows:, rowByIdentifier: and
// its query fetches. Their first column must be the identifier: the repository
// reads it to find an object it already has, without making a DTO.

- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row;

// nil if the query fails
- (nullable ZENResultSet *)allRows:(ZENDatabase *)database;

- (nullable ZENResultSet *)rowByIdentifier:(ZENIdentifier)identifier
								  database:(ZENDatabase *)database;

#pragma mark - Count

- (NSUInteger)countAllRows:(ZENDatabase *)database;

@end

NS_ASSUME_NONNULL_END
