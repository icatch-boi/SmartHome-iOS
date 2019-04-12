// SHProgressView.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/3/14 2:20 PM.
    

#import "SHProgressView.h"

@implementation SHProgressView

- (void)setProgress:(float)progress {
    _progress = progress;
    
    [self setTitle:[NSString stringWithFormat:@"%.2f%%", progress * 100] forState:UIControlStateNormal];
    
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    [self drawBackgroundCircle:rect];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect) * 0.5, CGRectGetHeight(rect) * 0.5);
    CGFloat radius = MIN(center.x, center.y) - 5;
    CGFloat startAngle = -M_PI_2;
    CGFloat endAngle = startAngle + self.progress * 2 * M_PI;
    
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    
    path.lineWidth = 5;
    path.lineCapStyle = kCGLineCapRound;
    [[UIColor blueColor] setStroke];
    
    [path stroke];
}

- (void)drawBackgroundCircle:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    CGPoint center = CGPointMake(CGRectGetWidth(rect) * 0.5, CGRectGetHeight(rect) * 0.5);
    CGFloat radius = MIN(center.x, center.y) - 5;
    CGFloat startAngle = 0;
    CGFloat endAngle = 2 * M_PI;
    
    [path addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    
    path.lineWidth = 5;
    path.lineCapStyle = kCGLineCapRound;
    [[UIColor lightGrayColor] setStroke];
    
    [path stroke];
}

@end
