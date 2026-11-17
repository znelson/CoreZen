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
