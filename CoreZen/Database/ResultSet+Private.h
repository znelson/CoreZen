//
//  ResultSet+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "ResultSet.h"

@class FMResultSet;
@class ZENDatabase;

@interface ZENResultSet (Private)

// The database hears about it when stepping through rows fails
+ (instancetype)resultSetWithFMResultSet:(FMResultSet *)fmResultSet database:(ZENDatabase *)database;

@end
