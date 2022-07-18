//
//  DatabaseSchema.h
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

@interface CZNDatabaseSchema : NSObject

+ (instancetype)schemaWithTableClasses:(NSArray *)tables;

- (void)initializeDatabase:(FMDatabase *)database;

@end
