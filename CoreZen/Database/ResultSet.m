//
//  ResultSet.m
//  CoreZen
//
//  Created by Zach Nelson on 4/1/26.
//

#import "ResultSet.h"
#import "ResultSet+Private.h"

@import FMDB;

@interface ZENResultSet ()
@property (nonatomic, strong, readonly) FMResultSet *fmResultSet;
@end

@implementation ZENResultSet

+ (instancetype)resultSetWithFMResultSet:(FMResultSet *)fmResultSet {
	ZENResultSet *rs = [[ZENResultSet alloc] init];
	if (rs) {
		rs->_fmResultSet = fmResultSet;
	}
	return rs;
}

- (BOOL)next  { return [self.fmResultSet next]; }
- (void)close { [self.fmResultSet close]; }

#pragma mark - By column index

- (int)intForColumnIndex:(int)columnIdx {
	return [self.fmResultSet intForColumnIndex:columnIdx];
}

- (long long)longLongIntForColumnIndex:(int)columnIdx {
	return [self.fmResultSet longLongIntForColumnIndex:columnIdx];
}

- (unsigned long long)unsignedLongLongIntForColumnIndex:(int)columnIdx {
	return [self.fmResultSet unsignedLongLongIntForColumnIndex:columnIdx];
}

- (double)doubleForColumnIndex:(int)columnIdx {
	return [self.fmResultSet doubleForColumnIndex:columnIdx];
}

- (BOOL)boolForColumnIndex:(int)columnIdx {
	return [self.fmResultSet boolForColumnIndex:columnIdx];
}

- (NSString *)stringForColumnIndex:(int)columnIdx {
	return [self.fmResultSet stringForColumnIndex:columnIdx];
}

- (NSData *)dataForColumnIndex:(int)columnIdx {
	return [self.fmResultSet dataForColumnIndex:columnIdx];
}

- (NSDate *)dateForColumnIndex:(int)columnIdx {
	return [self.fmResultSet dateForColumnIndex:columnIdx];
}

#pragma mark - By column name

- (int)intForColumn:(NSString *)columnName {
	return [self.fmResultSet intForColumn:columnName];
}

- (long long)longLongIntForColumn:(NSString *)columnName {
	return [self.fmResultSet longLongIntForColumn:columnName];
}

- (unsigned long long)unsignedLongLongIntForColumn:(NSString *)columnName {
	return [self.fmResultSet unsignedLongLongIntForColumn:columnName];
}

- (double)doubleForColumn:(NSString *)columnName {
	return [self.fmResultSet doubleForColumn:columnName];
}

- (BOOL)boolForColumn:(NSString *)columnName {
	return [self.fmResultSet boolForColumn:columnName];
}

- (NSString *)stringForColumn:(NSString *)columnName {
	return [self.fmResultSet stringForColumn:columnName];
}

- (NSData *)dataForColumn:(NSString *)columnName {
	return [self.fmResultSet dataForColumn:columnName];
}

- (NSDate *)dateForColumn:(NSString *)columnName {
	return [self.fmResultSet dateForColumn:columnName];
}

@end
