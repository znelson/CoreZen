//
//  DatabaseStatement.h
//  CoreZen
//
//  Created by Zach Nelson on 3/10/22.
//

#import <Foundation/Foundation.h>

@interface CZNDatabaseStatement : NSObject

@property (nonatomic, strong) NSString *statement;
@property (nonatomic, strong) NSArray *values;

@end
