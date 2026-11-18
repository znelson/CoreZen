//
//  TestTable.h
//  CoreZenTests
//

#import <Foundation/Foundation.h>
#import <CoreZen/DatabaseTable.h>

@interface ZENTestTable : NSObject <ZENDatabaseTable>

@end

// Same columns as ZENTestTable, stored in a separate table
@interface ZENOtherTestTable : ZENTestTable

@end

// Its schema update to version 2 adds a column, then runs a statement that
// fails, as a broken migration might
@interface ZENBrokenMigrationTestTable : ZENTestTable

@end
