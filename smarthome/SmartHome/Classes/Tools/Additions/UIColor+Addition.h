//
//  UIColor+Addition.h
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Addition)

/// 使用 16 进制数字创建颜色，例如 0xFF0000 创建红色
///
/// @param hex 16 进制无符号32位整数 alpha default is 1.0
/// @return 颜色
+ (instancetype)ic_colorWithHex:(uint32_t)hex;
/// @param alpha 透明度
+ (instancetype)ic_colorWithHex:(uint32_t)hex alpha:(CGFloat)alpha;

/// 生成随机颜色
/// alpha default is 1.0
/// @return 随机颜色
+ (instancetype)ic_randomColor;
+ (instancetype)ic_randomColorWithAlpha:(CGFloat)alpha;

/// 使用 R / G / B 数值创建颜色
///
/// @param red   red
/// @param green green
/// @param blue  blue alpha default is 1.0
///
/// @return 颜色
+ (instancetype)ic_colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue;
+ (instancetype)ic_colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(CGFloat)alpha;

@end
