//
//  UIImage+ICAddition.m
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "UIImage+ICAddition.h"

@implementation UIImage (ICAddition)

- (UIImage *)ic_imageWithSize:(CGSize)size backColor:(UIColor *)color {
    CGSize curSize = size;
    if (curSize.width == 0 || curSize.height == 0) {
        curSize = self.size;
    }
    
    CGRect rect;
    rect.origin = CGPoint();
    rect.size = curSize;
    
    UIGraphicsBeginImageContextWithOptions(curSize, YES, 0);
    
    [color setFill];
    UIRectFill(rect);
    
    [self drawInRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)ic_avatarImageWithSize:(CGSize)size backColor:(UIColor *)color lineColor:(UIColor *)lineColor lineWidth:(CGFloat)lineWidth {
    CGSize curSize = size;
    if (curSize.width == 0 || curSize.height == 0) {
        curSize = self.size;
    }
    
    CGRect rect = CGRectMake(0, 0, curSize.width, curSize.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    [color setFill];
    UIRectFill(rect);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:rect];
    [path addClip];
    
    [self drawInRect:rect];
    
    UIBezierPath *ovalPath = [UIBezierPath bezierPathWithOvalInRect:rect];
    ovalPath.lineWidth = lineWidth;
    [lineColor setStroke];
    [ovalPath stroke];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)ic_cornerImageWithSize:(CGSize)size radius:(CGFloat)radius {
    return [self ic_cornerImageWithSize:size backColor:[UIColor whiteColor] radius:radius];
}

- (UIImage *)ic_cornerImageWithSize:(CGSize)size backColor:(UIColor *)color radius:(CGFloat)radius {
    return [self ic_cornerImageWithSize:size backColor:color byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

- (UIImage *)ic_cornerImageWithSize:(CGSize)size backColor:(UIColor *)color byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii {
    CGSize curSize = size;
    if (curSize.width == 0 || curSize.height == 0) {
        curSize = self.size;
    }
    
    CGRect rect = CGRectMake(0, 0, curSize.width, curSize.height);
    
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    
    [color setFill];
    UIRectFill(rect);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:cornerRadii];
    [path addClip];
    
    [self drawInRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
