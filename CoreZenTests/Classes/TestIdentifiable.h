//
//  TestIdentifiable.h
//  CoreZenTests
//
//  Created by Zach Nelson on 3/23/22.
//

#import <Foundation/Foundation.h>
#import <CoreZen/Identifiable.h>

@interface ZENTestIdentifiable : NSObject <ZENIdentifiable>

@property (nonatomic, readonly) int64_t identifier;

+ (instancetype)testIdentifiableWithIdentifier:(ZENIdentifier)identifier;
- (instancetype)initWithIdentifier:(ZENIdentifier)identifier;

@end

