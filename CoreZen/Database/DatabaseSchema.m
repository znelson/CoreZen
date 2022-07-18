//
//  DatabaseSchema.m
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import "DatabaseSchema.h"
#import "DatabaseTable.h"
#import "ObjectIdentifier.h"

@import FMDB;

@interface ZENDatabaseSchema ()

@property (nonatomic, strong) NSArray *tableClasses;

- (instancetype)initWithTableClasses:(NSArray *)tableClasses;

- (NSArray *)tableNames;

- (BOOL)updateDatabaseSchema:(FMDatabase *)database;
- (void)initializeIdentifiers:(FMDatabase *)database;

@end

@implementation ZENDatabaseSchema

- (instancetype)initWithTableClasses:(NSArray *)tableClasses {
	self = [super init];
	if (self) {
		self.tableClasses = tableClasses;
	}
	return self;
}

+ (instancetype)schemaWithTableClasses:(NSArray *)tables {
	return [[ZENDatabaseSchema alloc] initWithTableClasses:tables];
}

- (void)initializeDatabase:(FMDatabase *)database {
	// Update the database schema to the latest version
	[database beginTransaction];
	if ([self updateDatabaseSchema:database]) {
		[database commit];
	} else {
		[database rollback];
	}
	// Initialize the global identifiers from database tables
	[self initializeIdentifiers:database];
}

- (NSArray *)tableNames {
	static NSMutableArray *tableNames = nil;
	if (!tableNames) {
		tableNames = [NSMutableArray array];
		for (Class<ZENDatabaseTable> tableClass in self.tableClasses) {
			[tableNames addObject:[tableClass tableName]];
		}
	}
	return tableNames;
}

- (BOOL)updateDatabaseSchema:(FMDatabase *)database {
	NSUInteger startingVersion = 0;
	FMResultSet *rs = [database executeQuery:@"PRAGMA user_version"];
	if ([rs next]) {
		startingVersion = [rs unsignedLongLongIntForColumnIndex:0];
	}
	[rs close];
	
	NSUInteger schemaVersion = startingVersion;
	
	while (YES) {
		NSUInteger updatedVersion = schemaVersion + 1;
		for (Class<ZENDatabaseTable> tableClass in self.tableClasses) {
			if ([tableClass updateSchema:database version:updatedVersion]) {
				schemaVersion = updatedVersion;
			}
		}
		if (schemaVersion != updatedVersion) {
			break;
		}
	}
	
	BOOL versionChanged = (schemaVersion != startingVersion);
	if (versionChanged) {
		NSLog(@"Schema updated from version %lu to %lu", startingVersion, schemaVersion);
		NSString *statement = [NSString stringWithFormat:@"PRAGMA user_version = %lu", schemaVersion];
		[database executeUpdate:statement];
	}
	return versionChanged;
}

- (void)initializeIdentifiers:(FMDatabase *)database {
	for (NSString *tableName in self.tableNames) {
		NSString *statement = [NSString stringWithFormat:@"SELECT identifier FROM %@ ORDER BY identifier DESC LIMIT 1;", tableName];
		FMResultSet *rs = [database executeQuery:statement];
		if ([rs next]) {
			ZENIdentifier largestIdentifier = [rs longLongIntForColumnIndex:0];
			NSLog(@"Setting largest identifier to %lli (from %@)", largestIdentifier, tableName);
			ZENSetLargestObjectIdentifier(largestIdentifier);
		}
		[rs close];
	}
}

@end
