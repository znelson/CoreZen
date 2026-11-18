//
//  DatabaseSchema.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class ZENDatabase;

@interface ZENDatabaseSchema : NSObject

+ (instancetype)schemaWithTableClasses:(NSArray *)tables;

// Updates the schema to the latest version in a transaction, joining the
// caller's if one is open. If any statement fails, the whole update rolls back,
// so it runs again the next time.
- (void)initializeDatabase:(ZENDatabase *)database;

@end
