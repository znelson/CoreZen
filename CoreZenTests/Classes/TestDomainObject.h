//
//  TestDomainObject.h
//  CoreZenTests
//

#import <CoreZen/DomainObject.h>

@interface ZENTestDomainObject : ZENDomainObject

// From the DTO's name, and kept up to date by didUpdateDTO
@property (nonatomic, copy, readonly) NSString *name;
// How many times didUpdateDTO has run
@property (atomic, readonly) NSUInteger dtoUpdateCount;

@end

// Finishes performAsyncInit: after a short delay, and counts how often it ran
@interface ZENSlowInitDomainObject : ZENTestDomainObject

@property (atomic, readonly) BOOL initialized;
@property (atomic, readonly) NSInteger asyncInitCount;

@end

// Calls its performAsyncInit: completion twice, as a buggy subclass might
@interface ZENDoubleCompletionDomainObject : ZENTestDomainObject

@end

extern NSString *const ZENTestErrorDomain;

// Fails its performAsyncInit: right away when its name starts with "Fail"
@interface ZENFailableInitDomainObject : ZENTestDomainObject

@end

// Fails its performAsyncInit: after the same delay as ZENSlowInitDomainObject
@interface ZENSlowFailingInitDomainObject : ZENSlowInitDomainObject

@end

// The data model for ZENCountedInitDomainObjects. It calls repeatedInit when an
// identifier's async init starts for a second time.
@interface ZENInitCountingModel : NSObject <ZENDataModel>

@property (atomic, copy) void (^repeatedInit)(ZENIdentifier identifier);

- (void)countInitOf:(ZENIdentifier)identifier;

@end

// Its performAsyncInit: tells its model, a ZENInitCountingModel
@interface ZENCountedInitDomainObject : ZENTestDomainObject

@end
