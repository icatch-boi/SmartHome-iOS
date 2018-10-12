//
//  UIImage+ICAddition.h
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ICAddition)

/**
 生成指定大小的不透明图象

 @param size 尺寸
 @param color 背景颜色
 @return 指定大小的不透明图像
 */
- (UIImage *)ic_imageWithSize:(CGSize)size backColor:(UIColor *)color;

/**
 创建头像图像

 @param size 尺寸
 @param color 背景颜色
 @param lineColor 边线颜色
 @param lineWidth 边线宽度
 @return 指定大小的头像
 */
- (UIImage *)ic_avatarImageWithSize:(CGSize)size backColor:(UIColor *)color lineColor:(UIColor *)lineColor lineWidth:(CGFloat)lineWidth;


/**
 创建圆角图像

 @param size 尺寸
 @param radius 圆角半径
 @param color 背景颜色
 @return 带圆角的不透明图像
 */
- (UIImage *)ic_cornerImageWithSize:(CGSize)size radius:(CGFloat)radius;
- (UIImage *)ic_cornerImageWithSize:(CGSize)size backColor:(UIColor *)color radius:(CGFloat)radius;
- (UIImage *)ic_cornerImageWithSize:(CGSize)size backColor:(UIColor *)color byRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii;

@end
