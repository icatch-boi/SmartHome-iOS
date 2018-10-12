//
//  SHMpbTool.h
//  SmartHome
//
//  Created by ZJ on 2017/6/21.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHGUIHandleTool : NSObject

+ (void)setViewHidden:(BOOL)hidden andView:(UIView *)view;
+ (void)setButtonEnabled:(BOOL)enabled andButton:(UIButton *)btn;
+ (void)setButtonBackgroundColor:(UIColor *)color andButton:(UIButton *)btn;
+ (void)setButtonTitleColor:(UIColor *)color andButton:(UIButton *)btn;
+ (void)setButtonRadius:(UIButton *)button withRadius:(CGFloat)radius;

@end
