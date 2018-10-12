//
//  UIColor+Addition.m
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "UIColor+Addition.h"

@implementation UIColor (Addition)

+ (instancetype)ic_colorWithHex:(uint32_t)hex {
    return [self ic_colorWithHex:hex alpha:1.0];
}

+ (instancetype)ic_colorWithHex:(uint32_t)hex alpha:(CGFloat)alpha {
    uint8_t r = (hex & 0xff0000) >> 16;
    uint8_t g = (hex & 0x00ff00) >> 8;
    uint8_t b = hex & 0x0000ff;
    
    return [self ic_colorWithRed:r green:g blue:b alpha:alpha];
}


+ (instancetype)ic_randomColor {
    return [self ic_randomColorWithAlpha:1.0];
}

+ (instancetype)ic_randomColorWithAlpha:(CGFloat)alpha {
    return [self ic_colorWithRed:arc4random_uniform(256) green:arc4random_uniform(256) blue:arc4random_uniform(256) alpha:alpha];
}


+ (instancetype)ic_colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue {
    return [self ic_colorWithRed:red green:green blue:blue alpha:1.0];
}

+ (instancetype)ic_colorWithRed:(uint8_t)red green:(uint8_t)green blue:(uint8_t)blue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:alpha];
}

@end
