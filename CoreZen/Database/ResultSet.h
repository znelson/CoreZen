//
//  ResultSet.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZENResultSet : NSObject

- (BOOL)next;
- (void)close;

#pragma mark - By column index

// The object getters return nil for a NULL value

- (int)intForColumnIndex:(int)columnIdx;
- (long long)longLongIntForColumnIndex:(int)columnIdx;
- (unsigned long long)unsignedLongLongIntForColumnIndex:(int)columnIdx;
- (double)doubleForColumnIndex:(int)columnIdx;
- (BOOL)boolForColumnIndex:(int)columnIdx;
- (nullable NSString *)stringForColumnIndex:(int)columnIdx;
- (nullable NSData *)dataForColumnIndex:(int)columnIdx;
- (nullable NSDate *)dateForColumnIndex:(int)columnIdx;

#pragma mark - By column name

- (int)intForColumn:(NSString *)columnName;
- (long long)longLongIntForColumn:(NSString *)columnName;
- (unsigned long long)unsignedLongLongIntForColumn:(NSString *)columnName;
- (double)doubleForColumn:(NSString *)columnName;
- (BOOL)boolForColumn:(NSString *)columnName;
- (nullable NSString *)stringForColumn:(NSString *)columnName;
- (nullable NSData *)dataForColumn:(NSString *)columnName;
- (nullable NSDate *)dateForColumn:(NSString *)columnName;

@end

NS_ASSUME_NONNULL_END
