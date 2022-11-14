//
//  DatabaseQueue.m
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import "DatabaseQueue.h"
#import "WorkQueue.h"

#import <stdatomic.h>

@import FMDB;

@interface ZENDatabaseQueue ()

- (void)internalInit:(NSString *)queueLabel;
- (instancetype)initInMemory;
- (instancetype)initWithURL:(NSURL *)URL;
- (FMDatabase *)threadDatabase;

@property (nonatomic, strong, readonly) NSURL *databaseURL;
@property (nonatomic, strong, readonly) NSString *databaseKey;
@property (nonatomic, strong, readonly) ZENWorkQueue *workQueue;

@end;

@implementation ZENDatabaseQueue

- (void)internalInit:(NSString *)queueLabel {
	_workQueue = [ZENWorkQueue workQueue:queueLabel];
}

- (instancetype)initInMemory {
	self = [super init];
	if (self) {
		NSLog(@"Database in memory");
		_databaseURL = nil;
		
		static atomic_uint_fast64_t nextIdentifier = 0;
		uint64_t cacheID = atomic_fetch_add(&nextIdentifier, 1);

		NSString *databaseID = [NSString stringWithFormat:@"corezen-mem-db-%llu", cacheID];
		
		_databaseKey = [NSString stringWithFormat:@"file:%@?mode=memory&cache=shared", databaseID];
	
		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-InMemory-%llu", cacheID];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueInMemory {
	return [[ZENDatabaseQueue alloc] initInMemory];
}

- (instancetype)initWithURL:(NSURL *)URL {
	self = [super init];
	if (self) {
		NSLog(@"Database at: %@", URL);
		_databaseURL = URL;
		_databaseKey = URL.path;
		
		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-%@", [URL lastPathComponent]];
		[self internalInit:queueLabel];
	}
	return self;
}

+ (instancetype)databaseQueueWithURL:(NSURL *)URL {
	return [[ZENDatabaseQueue alloc] initWithURL:URL];
}

- (void)shutdown {
	[self shutdown:nil];
}

- (void)shutdown:(ZENDatabaseBlock)updateBlock {
	NSLog(@"Terminating database queue...");
	[self.workQueue terminate:^{
		if (updateBlock) {
			@autoreleasepool {
				FMDatabase *database = self.threadDatabase;
				updateBlock(database);
			}
		}
		NSLog(@"Finished terminating database queue");
	}];
}

- (FMDatabase *)threadDatabase {
	// Make an instance of FMDatabase for the thread, store it in the thread dictionary.
	// FMDB wants a different database instance per thread, and serial queue may run on different threads.
	// (Serial queue is guaranteed to be serial, not necessary on a single thread.)
	
	NSMutableDictionary *threadDictionary = NSThread.currentThread.threadDictionary;
	FMDatabase *database = [threadDictionary objectForKey:self.databaseKey];
	
	if (database == nil) {
		NSLog(@"Creating database for thread %@ at %@", [NSThread currentThread], self.databaseURL);
		
		if (self.databaseURL) {
			database = [FMDatabase databaseWithURL:self.databaseURL];
		} else {
			database = [FMDatabase databaseWithPath:self.databaseKey];
		}
		
		[database open];
		[database executeUpdate:@"PRAGMA synchronous = 1;"];
		[database setShouldCacheStatements:YES];
		
		// TODO: Disable for release builds?
		[database setTraceExecution:YES];
		
		[threadDictionary setObject:database forKey:self.databaseKey];
	}
	
	return database;
}

- (void)transactionAsync:(ZENDatabaseBlock)updateBlock {
	[self.workQueue async:^(ZENCancelToken *canceled) {
		if (!canceled.canceled) {
			@autoreleasepool {
				FMDatabase *database = self.threadDatabase;
				[database beginTransaction];
				updateBlock(database);
				[database commit];
			}
		}
	}];
}

- (void)transactionSync:(ZENDatabaseBlock)updateBlock {
	[self.workQueue sync:^{
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			[database beginTransaction];
			updateBlock(database);
			[database commit];
		}
	}];
}

- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock {
	[self.workQueue async:^(ZENCancelToken *canceled) {
		if (!canceled.canceled) {
			@autoreleasepool {
				FMDatabase *database = self.threadDatabase;
				fetchBlock(database);
			}
		}
	}];
}

- (void)fetchSync:(ZENDatabaseBlock)fetchBlock {
	[self.workQueue sync:^{
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			fetchBlock(database);
		}
	}];
}

- (void)vacuumAsync {
	[self.workQueue async:^(ZENCancelToken *canceled) {
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			[database executeUpdate:@"VACUUM;"];
		}
	}];
}

@end
