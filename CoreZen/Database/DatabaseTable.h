//
//  DatabaseTable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class FMResultSet;
@class ZENDataTransferObject;

#import <CoreZen/Identifier.h>

@protocol ZENDatabaseTable

#pragma mark - Metadata

+ (NSString *)tableName;

+ (BOOL)updateSchema:(FMDatabase *)database
			 version:(NSUInteger)version;

#pragma mark - Create

- (BOOL)insertDTO:(ZENDataTransferObject *)dto
		 database:(FMDatabase *)database;

#pragma mark - Update

- (BOOL)updateDTO:(ZENDataTransferObject *)dto
		 database:(FMDatabase *)database;

#pragma mark - Delete

- (BOOL)deleteByIdentifier:(ZENIdentifier)identifier
				  database:(FMDatabase *)database;

#pragma mark - Read

- (ZENDataTransferObject *)dtoFromRow:(FMResultSet *)row;

- (FMResultSet *)allRows:(FMDatabase *)database;

- (FMResultSet *)rowByIdentifier:(ZENIdentifier)identifier
						database:(FMDatabase *)database;

#pragma mark - Count

- (NSUInteger)countAllRows:(FMDatabase *)database;

#pragma mark - [optional] Count

@optional

- (NSUInteger)sumAllVideoDuration:(FMDatabase *)database;

@end
