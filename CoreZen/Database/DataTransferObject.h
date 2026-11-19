//
//  DataTransferObject.h
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#import <CoreZen/Identifiable.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZENDataTransferObject : NSObject <ZENIdentifiable>

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier;

@end

NS_ASSUME_NONNULL_END
