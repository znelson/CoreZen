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

- (void)initializeDatabase:(ZENDatabase *)database;

@end
