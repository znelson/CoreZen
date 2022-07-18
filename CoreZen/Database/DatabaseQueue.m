//
//  DatabaseQueue.m
//  CoreZen
//
//  Created by Zach Nelson on 5/21/19.
//

#import "DatabaseQueue.h"

@import FMDB;

#import <stdatomic.h>

#define RETURN_IF_TERMINATING if (atomic_load(&self->_terminating)) { return; }
#define RETURN_IF_TERMINATED if (self->_terminated) { return; }

@interface ZENDatabaseQueue ()
{
	atomic_bool _terminating;
	BOOL _terminated;
}

- (void)internalInit:(NSString *)queueLabel;
- (instancetype)initInMemory;
- (instancetype)initWithURL:(NSURL *)URL;
- (FMDatabase *)threadDatabase;

@property (nonatomic, strong, readonly) NSString *queueLabel;
@property (nonatomic, strong, readonly) NSURL *databaseURL;
@property (nonatomic, strong, readonly) NSString *databaseKey;
@property (nonatomic, strong, readonly) dispatch_queue_t dispatchQueue;

@end;

@implementation ZENDatabaseQueue

- (void)internalInit:(NSString *)queueLabel {
	_queueLabel = queueLabel;
	_dispatchQueue = dispatch_queue_create(queueLabel.UTF8String, DISPATCH_QUEUE_SERIAL);
	atomic_store(&_terminating, false);
	_terminated = NO;
}

- (instancetype)initInMemory {
	self = [super init];
	if (self) {
		NSLog(@"Database in memory");
		_databaseURL = nil;
		
		static NSUInteger cacheID = 0;
		NSString *databaseID = [NSString stringWithFormat:@"corezen-mem-db-%lu", cacheID];
		
		_databaseKey = [NSString stringWithFormat:@"file:%@?mode=memory&cache=shared", databaseID];
	
		NSString *queueLabel = [NSString stringWithFormat:@"ZENDatabaseQueue-InMemory-%lu", cacheID];
		[self internalInit:queueLabel];
		
		cacheID++;
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
	bool expected = false;
	if (!atomic_compare_exchange_strong(&_terminating, &expected, true)) {
		return;
	}
	NSLog(@"Terminating database queue %@...", self.queueLabel);
	dispatch_sync(self.dispatchQueue, ^{
		if (updateBlock) {
			@autoreleasepool {
				FMDatabase *database = self.threadDatabase;
				updateBlock(database);
			}
		}
		_terminated = YES;
		NSLog(@"Finished terminating database queue %@", self.queueLabel);
	});
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
	RETURN_IF_TERMINATING;
	dispatch_async(self.dispatchQueue, ^{
		RETURN_IF_TERMINATED;
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			[database beginTransaction];
			updateBlock(database);
			[database commit];
		}
	});
}

- (void)transactionSync:(ZENDatabaseBlock)updateBlock {
	RETURN_IF_TERMINATING;
	dispatch_sync(self.dispatchQueue, ^{
		RETURN_IF_TERMINATED;
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			[database beginTransaction];
			updateBlock(database);
			[database commit];
		}
	});
}

- (void)fetchAsync:(ZENDatabaseBlock)fetchBlock {
	RETURN_IF_TERMINATING;
	dispatch_async(self.dispatchQueue, ^{
		RETURN_IF_TERMINATED;
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			fetchBlock(database);
		}
	});
}

- (void)fetchSync:(ZENDatabaseBlock)fetchBlock {
	RETURN_IF_TERMINATING;
	dispatch_sync(self.dispatchQueue, ^{
		RETURN_IF_TERMINATED;
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			fetchBlock(database);
		}
	});
}

- (void)vacuumAsync {
	RETURN_IF_TERMINATING;
	dispatch_async(self.dispatchQueue, ^{
		RETURN_IF_TERMINATED;
		@autoreleasepool {
			FMDatabase *database = self.threadDatabase;
			[database executeUpdate:@"VACUUM;"];
		}
	});
}

@end
