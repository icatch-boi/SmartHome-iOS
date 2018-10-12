//
//  SHGettingSupportedProperty.h
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHPropertyQueryResult.h"

@interface SHGettingSupportedProperty : NSObject

+ (instancetype)gettingSupportedPropertyWithControl:(Control *)control;
- (void)addProperty:(int)propertyId;
- (SHPropertyQueryResult *)submit;
- (NSInteger)getPropertyListSize;
- (void)clear;
- (ICatchTransProperty *)createGetProperty:(int)propertyId;

@end
