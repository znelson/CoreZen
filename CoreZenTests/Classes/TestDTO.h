//
//  TestDTO.h
//  CoreZenTests
//

#import <CoreZen/DataTransferObject.h>

@interface ZENTestDTO : ZENDataTransferObject

@property (nonatomic, copy) NSString *name;

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier name:(NSString *)name;

@end
