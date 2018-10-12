//
//  SHMpbTool.m
//  SmartHome
//
//  Created by ZJ on 2017/6/21.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHGUIHandleTool.h"

@implementation SHGUIHandleTool

+ (void)setViewHidden:(BOOL)hidden andView:(UIView *)view {
    view.hidden = hidden;
}

+ (void)setButtonEnabled:(BOOL)enabled andButton:(UIButton *)btn {
    btn.enabled = enabled;
}

+ (void)setButtonBackgroundColor:(UIColor *)color andButton:(UIButton *)btn {
    btn.backgroundColor = color;
}

+ (void)setButtonTitleColor:(UIColor *)color andButton:(UIButton *)btn {
    [btn setTitleColor:color forState:UIControlStateNormal];
}

+ (void)setButtonRadius:(UIButton *)button withRadius:(CGFloat)radius {
//    button.layer.cornerRadius = radius;
//    button.layer.masksToBounds = YES;
    [button setCornerWithRadius:radius];
    //    button.backgroundColor = kBackgroundColor;
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

@end
