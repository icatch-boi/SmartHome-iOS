//
//  SHWaterView.m
//  SmartHome
//
//  Created by ZJ on 2018/1/12.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHWaterView.h"

@implementation SHWaterView


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    // 半径
    CGFloat radius = _radius != 0 ? _radius : 50;
    // 开始角
    CGFloat startAngle = 0;
    
    // 中心点
    CGPoint point = CGPointMake(rect.size.width * 0.5, rect.size.height * 0.5);  // 中心点
    
    // 结束角
    CGFloat endAngle = 2*M_PI;
    
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:point radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.path = path.CGPath;       // 添加路径 下面三个同理
    layer.lineWidth = 1.5f;
    
    UIColor *strokeColor = _strokeColor ? _strokeColor : [UIColor redColor];
    UIColor *fillColor = _fillColor ? _fillColor : [UIColor clearColor];
    
    layer.strokeColor = strokeColor.CGColor;
    layer.fillColor = fillColor.CGColor;
    
    [self.layer addSublayer:layer];
}


@end
