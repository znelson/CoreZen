//
//  TestTable.h
//  CoreZenTests
//

#import <Foundation/Foundation.h>
#import <CoreZen/DatabaseTable.h>

@interface ZENTestTable : NSObject <ZENDatabaseTable>

// Rows whose name matches a LIKE pattern, by name from Z to A: a query of the
// table's own, for repository query fetches
- (ZENResultSet *)rowsWithNamesLike:(NSString *)pattern database:(ZENDatabase *)database;

@end

// Same columns as ZENTestTable, stored in a separate table
@interface ZENOtherTestTable : ZENTestTable

@end

// Its schema update to version 2 adds a column, then runs a statement that
// fails, as a broken migration might
@interface ZENBrokenMigrationTestTable : ZENTestTable

@end

// Its schema update to version 1 creates its table, then leaves a row whose
// deferred foreign key refers to no row. With foreign keys enforced, the update's
// statements succeed and its commit fails.
@interface ZENUncommittableMigrationTestTable : ZENTestTable

@end

// Reads test_objects like ZENTestTable, but its writes report failure without
// running a statement, as a table with checks of its own might
@interface ZENRefusingTestTable : ZENTestTable

@end
