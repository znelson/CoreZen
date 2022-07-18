//
//  DatabaseTable.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class FMDatabase;
@class FMResultSet;
@class CZNDTO;

#import <CoreZen/Identifier.h>

@protocol CZNDatabaseTable

#pragma mark - Metadata

+ (NSString *)tableName;

+ (BOOL)updateSchema:(FMDatabase *)database
			 version:(NSUInteger)version;

#pragma mark - Create

- (BOOL)insertDTO:(CZNDTO *)dto
		 database:(FMDatabase *)database;

#pragma mark - Update

- (BOOL)updateDTO:(CZNDTO *)dto
		 database:(FMDatabase *)database;

#pragma mark - Delete

- (BOOL)deleteByIdentifier:(CZNIdentifier)identifier
				  database:(FMDatabase *)database;

#pragma mark - Read

- (CZNDTO *)dtoFromRow:(FMResultSet *)row;

- (FMResultSet *)allRows:(FMDatabase *)database;

- (FMResultSet *)rowByIdentifier:(CZNIdentifier)identifier
						database:(FMDatabase *)database;

#pragma mark - Count

- (NSUInteger)countAllRows:(FMDatabase *)database;

#pragma mark - [optional] Count

@optional

- (NSUInteger)sumAllVideoDuration:(FMDatabase *)database;

@end
