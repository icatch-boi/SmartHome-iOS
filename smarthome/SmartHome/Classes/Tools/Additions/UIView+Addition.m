//
//  UIView+Addition.m
//  SmartHome
//
//  Created by ZJ on 2017/8/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "UIView+Addition.h"

@implementation UIView (Addition)

- (void)setCornerWithRadius:(CGFloat)radius {
    [self setCornerWithRadius:radius masksToBounds:NO];
}

- (void)setCornerWithRadius:(CGFloat)radius masksToBounds:(BOOL)masks {
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = masks;
}

- (void)setCornerWithRoundingCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    [self setCornerWithRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
}

- (void)setCornerWithRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:corners cornerRadii:cornerRadii];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.layer.mask = maskLayer;
}

- (double)roundbyunit:(double)num unit:(double)unit {
    double remain = modf(num, &unit);
    if (remain > unit / 2.0) {
        return [self ceilbyunit:num unit:unit];
    } else {
        return [self floorbyunit:num unit:unit];
    }
}

- (double)ceilbyunit:(double)num unit:(double)unit {
    return num - modf(num, &unit) + unit;
}

- (double)floorbyunit:(double)num unit:(double)unit {
    return num - modf(num, &unit);
}

- (double)pixel:(double)num {
    double unit;
    int scale = UIScreen.mainScreen.scale;
    switch (scale) {
        case 1:
            unit = 1.0 / 1.0;
            break;
        case 2:
            unit = 1.0 / 2.0;
            break;
        case 3:
            unit = 1.0 / 3.0;
            break;
    default:
            unit = 0.0;
            break;
    }
    
    return [self roundbyunit:num unit:unit];
}

- (void)addCorner:(CGFloat)radius {
    [self addCorner:radius borderWidth:1 backgroundColor:[UIColor clearColor] borderColor:[UIColor blackColor]];
}

- (void)addCorner:(CGFloat)radius
      borderWidth:(CGFloat)borderWidth
  backgroundColor:(UIColor *)backgroundColor
      borderColor:(UIColor *)borderColor {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self drawRectWithRoundedCorner:radius borderWidth:borderWidth backgroundColor:backgroundColor borderColor:borderColor]];
    [self insertSubview:imageView atIndex:0];
}

- (UIImage *)drawRectWithRoundedCorner:(CGFloat)radius
                                  borderWidth:(CGFloat)borderWidth
                                  backgroundColor:(UIColor *)backgroundColor
                                  borderColor:(UIColor *)borderColor {
    CGSize sizeToFit = CGSizeMake([self pixel:self.bounds.size.width], self.bounds.size.height);
    CGFloat halfBorderWidth = CGFloat(borderWidth / 2.0);
    
    UIGraphicsBeginImageContextWithOptions(sizeToFit, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
    
    CGFloat width = sizeToFit.width;
    CGFloat height = sizeToFit.height;
    CGContextMoveToPoint(context, width - halfBorderWidth, radius + halfBorderWidth);  // 开始坐标右边开始
    CGContextAddArcToPoint(context, width - halfBorderWidth, height - halfBorderWidth, width - radius - halfBorderWidth, height - halfBorderWidth, radius);  // 右下角角度
    CGContextAddArcToPoint(context, halfBorderWidth, height - halfBorderWidth, halfBorderWidth, height - radius - halfBorderWidth, radius); // 左下角角度
    CGContextAddArcToPoint(context, halfBorderWidth, halfBorderWidth, width - halfBorderWidth, halfBorderWidth, radius); // 左上角
    CGContextAddArcToPoint(context, width - halfBorderWidth, halfBorderWidth, width - halfBorderWidth, radius + halfBorderWidth, radius); // 右上角
    CGContextDrawPath(context, kCGPathFillStroke);

    UIImage *output = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return output;
}

- (void)setBorderWidth:(CGFloat)width borderColor:(UIColor *)color {
    [self.layer setBorderWidth:width];
    
    if (color != nil) {
        self.layer.borderColor = color.CGColor;
    } else {
        self.layer.borderColor = [UIColor grayColor].CGColor;
    }
}

@end
