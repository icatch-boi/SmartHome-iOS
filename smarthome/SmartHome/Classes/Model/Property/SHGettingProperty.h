//
//  SHGettingProperty.h
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHSDK.h"
#include "type/ICatchTransPropertyID.h"
#include "SHPropertyQueryResult.h"

@interface SHGettingProperty : NSObject

+ (instancetype)gettingPropertyWithControl:(Control *)control;
- (void)addProperty:(int)propertyId;
- (void)addProperty:(int)propertyId withStringValue:(NSString*)stringValue;
- (SHPropertyQueryResult *)submit;

@end
