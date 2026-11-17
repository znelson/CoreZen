//
//  TestDomainObject.h
//  CoreZenTests
//

#import <CoreZen/DomainObject.h>

@interface ZENTestDomainObject : ZENDomainObject

@property (nonatomic, copy, readonly) NSString *name;

@end

// Finishes performAsyncInit: after a short delay, and counts how often it ran
@interface ZENSlowInitDomainObject : ZENTestDomainObject

@property (atomic, readonly) BOOL initialized;
@property (atomic, readonly) NSInteger asyncInitCount;

@end

// Calls its performAsyncInit: completion twice, as a buggy subclass might
@interface ZENDoubleCompletionDomainObject : ZENTestDomainObject

@end
