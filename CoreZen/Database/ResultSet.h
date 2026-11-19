//
//  ResultSet.h
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// The rows a query returned, read one at a time.
///
/// A result set starts before the first row. Call ``next`` to move to each row
/// in turn, then read the row's values by column index, counting from 0, or by
/// column name. Close it once you're done with it, especially before reading
/// every row, so SQLite can finish the statement. Releasing it closes it too.
@interface ZENResultSet : NSObject

/// Moves to the next row.
///
/// It returns NO once there are no more rows, or if reading the next one fails,
/// which in a transaction makes the transaction roll back.
- (BOOL)next;

/// Closes the result set, which finishes its statement.
- (void)close;

#pragma mark - By column index

/// The current row's value in the column at an index, as an `int`.
- (int)intForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as a `long long`.
- (long long)longLongIntForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as an `unsigned long long`.
- (unsigned long long)unsignedLongLongIntForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as a `double`.
- (double)doubleForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as a `BOOL`: YES for anything but 0.
- (BOOL)boolForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as a string, or nil for NULL.
- (nullable NSString *)stringForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as data, or nil for NULL.
- (nullable NSData *)dataForColumnIndex:(int)columnIdx;
/// The current row's value in the column at an index, as a date, from a number of seconds since 1970, or nil for NULL.
- (nullable NSDate *)dateForColumnIndex:(int)columnIdx;

#pragma mark - By column name

/// The current row's value in the column with a name, as an `int`.
- (int)intForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as a `long long`.
- (long long)longLongIntForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as an `unsigned long long`.
- (unsigned long long)unsignedLongLongIntForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as a `double`.
- (double)doubleForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as a `BOOL`: YES for anything but 0.
- (BOOL)boolForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as a string, or nil for NULL.
- (nullable NSString *)stringForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as data, or nil for NULL.
- (nullable NSData *)dataForColumn:(NSString *)columnName;
/// The current row's value in the column with a name, as a date, from a number of seconds since 1970, or nil for NULL.
- (nullable NSDate *)dateForColumn:(NSString *)columnName;

@end

NS_ASSUME_NONNULL_END
