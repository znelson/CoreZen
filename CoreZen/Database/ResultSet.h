//
//  ResultSet.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

@interface ZENResultSet : NSObject

- (BOOL)next;
- (void)close;

#pragma mark - By column index

- (int)intForColumnIndex:(int)columnIdx;
- (long long)longLongIntForColumnIndex:(int)columnIdx;
- (unsigned long long)unsignedLongLongIntForColumnIndex:(int)columnIdx;
- (double)doubleForColumnIndex:(int)columnIdx;
- (BOOL)boolForColumnIndex:(int)columnIdx;
- (NSString *)stringForColumnIndex:(int)columnIdx;
- (NSData *)dataForColumnIndex:(int)columnIdx;
- (NSDate *)dateForColumnIndex:(int)columnIdx;

#pragma mark - By column name

- (int)intForColumn:(NSString *)columnName;
- (long long)longLongIntForColumn:(NSString *)columnName;
- (unsigned long long)unsignedLongLongIntForColumn:(NSString *)columnName;
- (double)doubleForColumn:(NSString *)columnName;
- (BOOL)boolForColumn:(NSString *)columnName;
- (NSString *)stringForColumn:(NSString *)columnName;
- (NSData *)dataForColumn:(NSString *)columnName;
- (NSDate *)dateForColumn:(NSString *)columnName;

@end
