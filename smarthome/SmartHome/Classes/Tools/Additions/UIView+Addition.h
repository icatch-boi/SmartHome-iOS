//
//  UIView+Addition.h
//  SmartHome
//
//  Created by ZJ on 2017/8/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Addition)

/**
 设置view的Corner

 @param radius cornerRadius masksToBounds Defaults to NO
 @建议使用这一个API，当masksToBounds为YES时极其影响APP性能
 */
- (void)setCornerWithRadius:(CGFloat)radius;

/**
 设置view的Corner
 
 @param radius cornerRadius
 @param masks whether masks
 */
- (void)setCornerWithRadius:(CGFloat)radius masksToBounds:(BOOL)masks;


/**
 设置view的Corner

 @param corners corners
 @param radius cornerRadius
 */
- (void)setCornerWithRoundingCorners:(UIRectCorner)corners radius:(CGFloat)radius;

/**
  设置view的Corner

 @param corners corners
 @param cornerRadii cornerRadii
 */
- (void)setCornerWithRoundingCorners:(UIRectCorner)corners cornerRadii:(CGSize)cornerRadii;


/**
 设置view的Corner

 @param radius cornerRadius
 */
- (void)addCorner:(CGFloat)radius;

/**
 设置view的边框

 @param width 边框线宽
 @param color 边框颜色
 */
- (void)setBorderWidth:(CGFloat)width borderColor:(UIColor *)color;

@end
