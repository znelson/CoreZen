//
//  DatabaseQueue.h
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import <Foundation/Foundation.h>

@class FMDatabase;

typedef void (^ZENDatabaseBlock)(FMDatabase *database);

@interface ZENDatabaseQueue : NSObject

+ (instancetype)databaseQueueInMemory;
+ (instancetype)databaseQueueWithURL:(NSURL *)URL;

- (void)shutdown;
- (void)shutdown:(ZENDatabaseBlock)updateBlock;

- (void)transactionAsync:(ZENDatabaseBlock)updateBlock;
- (void)transactionSync:(ZENDatabaseBlock)updateBlock;
- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock;
- (void)fetchSync:(ZENDatabaseBlock)fetchBlock;
- (void)vacuumAsync;

@end
