//
//  DataTransferObject.h
//  CoreZen
//
//  Created by Zach Nelson on 3/15/22.
//

#include <CoreZen/Identifiable.h>
#include <Foundation/Foundation.h>

@interface ZENDataTransferObject : NSObject <ZENIdentifiable>

- (instancetype)initWithIdentifier:(ZENIdentifier)identifier;

@end
