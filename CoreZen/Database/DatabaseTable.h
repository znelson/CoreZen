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

- (ZENDataTransferObject *)dtoFromRow:(ZENResultSet *)row;

- (ZENResultSet *)allRows:(ZENDatabase *)database;

- (ZENResultSet *)rowByIdentifier:(ZENIdentifier)identifier
						 database:(ZENDatabase *)database;

#pragma mark - Count

- (NSUInteger)countAllRows:(ZENDatabase *)database;

#pragma mark - [optional] Count

@optional

- (NSUInteger)sumAllVideoDuration:(ZENDatabase *)database;

@end
