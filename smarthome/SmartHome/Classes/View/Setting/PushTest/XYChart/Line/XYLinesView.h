//
//  UULines.h
//  XYChart
//
//  Created by Daniel on 2018/7/22.
//  Copyright © 2018 uyiuyao. All rights reserved.
//

#import "XYChartProtocol.h"

@class XYChart;
@interface XYLinesView : UIView

- (void)setDataSource:(id<XYChartDataSource>)dataSource chartView:(XYChart *)chartView;

@end
