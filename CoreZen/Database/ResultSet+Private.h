//
//  ResultSet+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "ResultSet.h"

@class FMResultSet;

@interface ZENResultSet (Private)

+ (instancetype)resultSetWithFMResultSet:(FMResultSet *)fmResultSet;

@end
