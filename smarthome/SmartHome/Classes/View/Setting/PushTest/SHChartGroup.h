//
//  SHChartGroup.h
//  ICatchPushChart
//
//  Created by ZJ on 2018/10/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "XYChartDataSourceItem.h"

@interface SHChartGroup : XYChartDataSourceItem

@property (nonatomic, readonly) XYChartType type;

- (instancetype)initWithStyle:(XYChartType)type section:(NSUInteger)section row:(NSUInteger)row dataList:(NSArray <NSArray<NSString *>*> *)dataList;

- (instancetype)initWithStyle:(XYChartType)type section:(NSUInteger)section row:(NSUInteger)row width:(CGFloat)width dataList:(NSArray <NSArray<NSString *>*> *)dataList;

@end
