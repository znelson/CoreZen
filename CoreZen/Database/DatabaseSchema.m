//
//  DatabaseSchema.m
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import "DatabaseSchema.h"
#import "DatabaseTable.h"
#import "Database+Private.h"
#import "ResultSet.h"
#import "ObjectIdentifier+Private.h"
#import "Log.h"

@interface ZENDatabaseSchema ()

@property (nonatomic, strong) NSArray *tableClasses;

- (instancetype)initWithTableClasses:(NSArray *)tableClasses;

- (NSArray *)tableNames;

- (BOOL)updateDatabaseSchema:(ZENDatabase *)database;
- (void)initializeIdentifiers:(ZENDatabase *)database;

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

- (BOOL)initializeDatabase:(ZENDatabase *)database error:(NSError **)outError {
	// Update the database schema to the latest version, in a transaction of its
	// own unless the caller has one open. A failed statement makes the caller's
	// transaction roll back too.
	BOOL ownsTransaction = !database.inTransaction;
	if (ownsTransaction) {
		[database beginTransaction];
	}
	BOOL versionChanged = [self updateDatabaseSchema:database];
	NSError *updateError = database.rollbackError;
	if (updateError) {
		os_log_error(ZENLogDatabase(), "Rolling back the schema update: %{public}@", updateError.localizedDescription);
	}
	if (ownsTransaction) {
		if (versionChanged && !updateError) {
			if (![database commit]) {
				NSString *description =
					[NSString stringWithFormat:@"Couldn't commit the schema update: %@", database.lastErrorMessage];
				os_log_error(ZENLogDatabase(), "%{public}@, so rolling it back", description);
				updateError = ZENDatabaseErrorMake(ZENDatabaseErrorCommitFailed, description);
				// A failed commit can leave the transaction open, which would swallow
				// the queue's next transaction
				if (database.inTransaction) {
					[database rollback];
				}
			}
		} else {
			[database rollback];
		}
	}
	// Raise the global identifier counter past the tables' rows, which exist even
	// when the update failed
	[self initializeIdentifiers:database];

	if (updateError) {
		if (outError) {
			*outError = updateError;
		}
		return NO;
	}
	return YES;
}

// Deprecated, but still part of the API
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)initializeDatabase:(ZENDatabase *)database {
	[self initializeDatabase:database error:NULL];
}
#pragma clang diagnostic pop

- (NSArray *)tableNames {
	NSMutableArray *tableNames = [NSMutableArray array];
	for (Class<ZENDatabaseTable> tableClass in self.tableClasses) {
		[tableNames addObject:[tableClass tableName]];
	}
	return tableNames;
}

- (BOOL)updateDatabaseSchema:(ZENDatabase *)database {
	NSUInteger startingVersion = 0;
	ZENResultSet *rs = [database executeQuery:@"PRAGMA user_version"];
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
		// Later versions build on this one, and everything rolls back anyway
		if (database.rollbackError) {
			return NO;
		}
	}

	BOOL versionChanged = (schemaVersion != startingVersion);
	if (versionChanged) {
		os_log_info(ZENLogDatabase(), "Schema updated from version %lu to %lu", startingVersion, schemaVersion);
		NSString *statement = [NSString stringWithFormat:@"PRAGMA user_version = %lu", schemaVersion];
		[database executeUpdate:statement];
	}
	return versionChanged;
}

- (void)initializeIdentifiers:(ZENDatabase *)database {
	// Every table draws identifiers from the same global counter, so the counter
	// must resume after the largest identifier in any table, not the last one read.
	// It only ever moves forward: another database open in the process may have
	// handed out larger identifiers already.
	ZENIdentifier largestIdentifier = ZENInvalidIdentifier;
	NSString *largestTableName = nil;
	for (NSString *tableName in self.tableNames) {
		NSString *statement = [NSString stringWithFormat:@"SELECT identifier FROM %@ ORDER BY identifier DESC LIMIT 1;", tableName];
		ZENResultSet *rs = [database executeQuery:statement];
		if ([rs next]) {
			ZENIdentifier tableIdentifier = [rs longLongIntForColumnIndex:0];
			if (tableIdentifier > largestIdentifier) {
				largestIdentifier = tableIdentifier;
				largestTableName = tableName;
			}
		}
		[rs close];
	}
	if (largestTableName) {
		os_log_info(ZENLogDatabase(), "Largest identifier is %lli (in %{public}@)", largestIdentifier, largestTableName);
		ZENRaiseLargestObjectIdentifier(largestIdentifier);
	}
}

@end
