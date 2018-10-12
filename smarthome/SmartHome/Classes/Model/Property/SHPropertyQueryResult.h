//
//  SHPropertyQueryResult.h
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHRangeItem.h"

@interface SHPropertyQueryResult : NSObject

+ (instancetype)propertyQueryResultWithTransProperty:(list<ICatchTransProperty>)propertyList;
- (int)praseInt:(int)propertId;
- (NSString *)praseString:(int)propertId;
- (string)praseString2:(int)propertId;
- (SHRangeItem *)praseRangeItem:(int)propertId;
- (list<NSString*> *)praseRangeListString:(int)propertId;
- (list<int> *)praseRangeListInt:(int)propertId;

@end
