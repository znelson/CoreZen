//
//  FrameCollector.m
//  CoreZen
//
//  Created by Zach Nelson on 11/15/22.
//

#import "FrameCollector.h"
#import "FrameRenderer.h"

@interface ZENFrameCollector ()

@property (nonatomic) NSUInteger finishedCount;
@property (nonatomic, readonly) NSUInteger totalCount;
@property (nonatomic, strong, readonly) ZENRenderFramesResultsBlock completion;
@property (nonatomic, strong, readonly) NSMutableArray<ZENRenderedFrame *> *frames;
@property (nonatomic, strong, readonly) NSLock *lock;

- (instancetype)initWithCount:(NSUInteger)count
				   completion:(ZENRenderFramesResultsBlock)completion;

@end

@implementation ZENFrameCollector

- (instancetype)initWithCount:(NSUInteger)count
				   completion:(ZENRenderFramesResultsBlock)completion {
	self = [super init];
	if (self) {
		_finishedCount = 0;
		_totalCount = count;
		_completion = completion;
		_frames = [NSMutableArray new];
		_lock = [NSLock new];
	}
	return self;
}

+ (instancetype)frameCollectorWithCount:(NSUInteger)count
							 completion:(ZENRenderFramesResultsBlock)completion {
	return [[ZENFrameCollector alloc] initWithCount:count completion:completion];
}

- (void)collect:(ZENRenderedFrame *)frame {
	NSArray<ZENRenderedFrame *> *result = nil;
	
	[self.lock lock];
	
	if (frame.image) {
		[self.frames addObject:frame];
	}
	
	if (++self.finishedCount == self.totalCount) {
		result = self.frames;
	}

	[self.lock unlock];
	
	if (result) {
		self.completion(result);
	}
}

@end
