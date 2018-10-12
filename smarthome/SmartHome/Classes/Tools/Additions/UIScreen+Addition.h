//
//  UIScreen+Addition.h
//  SmartHome
//
//  Created by ZJ on 2017/8/7.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIScreen (Addition)

/**
 获取屏幕bounds
 
 @return 屏幕bounds
 */
+ (CGRect)screenBounds;

/**
 获取屏幕大小
 
 @return 屏幕大小
 */
+ (CGSize)screenSize;

/**
 获取屏幕宽度
 
 @return 屏幕宽度
 */
+ (CGFloat)screenWidth;

/**
 获取屏幕高度
 
 @return 屏幕高度
 */
+ (CGFloat)screenHeight;

/**
 获取屏幕分辨率
 
 @return 屏幕分辨率
 */
+ (CGFloat)scale;

@end
