//
//  WorkQueue+Private.h
//  CoreZen
//
//  Created by Zach Nelson on 11/14/22.
//

#import <CoreZen/WorkQueue.h>

@interface ZENWorkQueueMultiToken : ZENWorkQueueToken

- (instancetype)initWithTokens:(NSArray<ZENWorkQueueToken *> *)tokens;

@end
