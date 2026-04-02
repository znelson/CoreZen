//
//  Database+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "Database.h"

@class FMDatabase;

@interface ZENDatabase (Private)

+ (instancetype)databaseWithFMDatabase:(FMDatabase *)fmDatabase;

- (void)beginTransaction;
- (void)commit;
- (void)rollback;

- (void)setShouldCacheStatements:(BOOL)value;
- (void)setTraceExecution:(BOOL)value;

@end
