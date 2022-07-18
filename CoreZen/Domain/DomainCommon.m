//
//  DomainCommon.m
//  CoreZen
//
//  Created by Zach Nelson on 3/23/22.
//

#import "DomainCommon.h"

void ZENCallAsyncContinueBlockOnThreadPool(ZENAsyncContinueBlock continueBlock) {
	if (!continueBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		@autoreleasepool {
			continueBlock();
		}
	});
}

void ZENCallAsyncContinueBlockOnMainThread(ZENAsyncContinueBlock continueBlock) {
	if (!continueBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			continueBlock();
		}
	});
}

void ZENCallAsyncCompletionBlockOnThreadPool(ZENAsyncCompletionBlock completionBlock, NSError* error) {
	if (!completionBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		@autoreleasepool {
			completionBlock(error);
		}
	});
}

void ZENCallAsyncCompletionBlockOnMainThread(ZENAsyncCompletionBlock completionBlock, NSError* error) {
	if (!completionBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			completionBlock(error);
		}
	});
}

void ZENCallFetchResultsBlockOnThreadPool(ZENFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects) {
	if (!fetchResultsBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		@autoreleasepool {
			fetchResultsBlock(fetchedObjects);
		}
	});
}

void ZENCallFetchResultsBlockOnMainThread(ZENFetchResultsBlock fetchResultsBlock, NSArray *fetchedObjects) {
	if (!fetchResultsBlock) {
		return;
	}
	
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			fetchResultsBlock(fetchedObjects);
		}
	});
}

void ZENCallAsyncCountCompletionBlockOnThreadPool(ZENAsyncCountCompletionBlock countBlock, NSUInteger count) {
	if (!countBlock) {
		return;
	}

	dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
		@autoreleasepool {
			countBlock(count);
		}
	});
}

void ZENCallAsyncCountCompletionBlockOnMainThread(ZENAsyncCountCompletionBlock countBlock, NSUInteger count) {
	if (!countBlock) {
		return;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			countBlock(count);
		}
	});
}

void ZENDeliverNotificationOnMainThread(NSString* notification, id sender, NSDictionary *userData) {
	dispatch_async(dispatch_get_main_queue(), ^{
		@autoreleasepool {
			[NSNotificationCenter.defaultCenter postNotificationName:notification object:sender userInfo:userData];
		}
	});
}
