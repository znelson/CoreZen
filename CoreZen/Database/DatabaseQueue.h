//
//  DatabaseQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

typedef void (^CZNDatabaseBlock)(FMDatabase *database);

@interface CZNDatabaseQueue : NSObject

+ (instancetype)databaseQueueInMemory;
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;

- (void)shutdown;
- (void)shutdown:(CZNDatabaseBlock)updateBlock;

- (void)transactionAsync:(CZNDatabaseBlock)updateBlock;
- (void)transactionSync:(CZNDatabaseBlock)updateBlock;
- (void)fetchAsync:(CZNDatabaseBlock)fetchBlock;
- (void)fetchSync:(CZNDatabaseBlock)fetchBlock;
- (void)vacuumAsync;

@end
