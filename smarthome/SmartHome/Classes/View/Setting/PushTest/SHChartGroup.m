//
//  SHChartGroup.m
//  ICatchPushChart
//
//  Created by ZJ on 2018/10/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHChartGroup.h"
#import "XYChartItem.h"

@implementation SHChartGroup

- (instancetype)initWithStyle:(XYChartType)type section:(NSUInteger)section row:(NSUInteger)row dataList:(NSArray <NSArray<NSString *>*> *)dataList {
    self = [self initWithDataList:[SHChartGroup getDataListWithSection:section row:row dataList:dataList]];
    if (self) {
        _type = type;
        self.autoSizingRowWidth = YES;
    }
    
    return self;
}

- (instancetype)initWithStyle:(XYChartType)type section:(NSUInteger)section row:(NSUInteger)row width:(CGFloat)width dataList:(NSArray <NSArray<NSString *>*> *)dataList {
    self = [self initWithDataList:[SHChartGroup getDataListWithSection:section row:row dataList:dataList]];
    if (self) {
        _type = type;
        self.widthOfRow = width;
        self.autoSizingRowWidth = NO;
    }
    
    return self;
}

+ (NSArray<NSArray<id<XYChartItem>> *> *)getDataListWithSection:(NSUInteger)section row:(NSUInteger)row dataList:(NSArray <NSArray<NSString *>*> *)dataList
{
    NSArray * chartDataList = [(dataList && dataList.count > 0) ? dataList : [self randomSection:section row:row] xy_map:^id(NSArray<NSString *> *obj1, NSUInteger idx1) {
        return [obj1 xy_map:^id(NSString *obj, NSUInteger idx) {
            XYChartItem *item = [[XYChartItem alloc] init];
            NSArray *temp = [obj componentsSeparatedByString:@" "];
            NSString *valueStr = temp.lastObject;
            item.value = @(valueStr.integerValue);
            item.color = [UIColor blueColor]; //[UIColor xy_random];
            item.duration = 0.3;
            item.showName = temp.firstObject;
            return item;
        }];
    }];
    
    return chartDataList;
}

#pragma mark - helper for test
+ (NSArray <NSString *>*)randomStrings:(NSUInteger)count
{
    NSMutableArray <NSString *>*mArr = @[].mutableCopy;
    for (int i=0; i<count; i++) {
        NSInteger num = arc4random()%100;
        [mArr addObject:@(num).stringValue];
    }
    return [NSArray arrayWithArray:mArr];
}

+ (NSArray <NSArray<NSString *>*>*)randomSection:(NSUInteger)section row:(NSUInteger)row
{
    NSMutableArray <NSArray<NSString *>*>*mArr = @[].mutableCopy;
    for (int i=0; i<section; i++) {
        [mArr addObject:[self randomStrings:row]];
    }
    return [NSArray arrayWithArray:mArr];
}

@end
