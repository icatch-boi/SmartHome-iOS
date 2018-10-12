//
//  SHRangeItem.m
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHRangeItem.h"

@implementation SHRangeItem

+ (instancetype)rangeItemWithData:(NSInteger)min max:(NSInteger)max step:(NSInteger)step{
    SHRangeItem* rangeItem = [[SHRangeItem alloc] init];
    
    rangeItem.min = min;
    rangeItem.max = max;
    rangeItem.step = step;
    
    return rangeItem;
}

@end
