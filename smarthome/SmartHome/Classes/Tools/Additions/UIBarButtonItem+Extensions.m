// UIBarButtonItem+Extensions.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/5/17 下午1:37.
    

#import "UIBarButtonItem+Extensions.h"

@implementation UIBarButtonItem (Extensions)

#pragma clang diagnostic ignored "-Wobjc-designated-initializers"

- (instancetype)initWithTitle:(NSString *)title target:(id)target action:(SEL)action isBack:(BOOL)isBack {
    return [self initWithTitle:title fontSize:16.0 image:nil target:target action:action isBack:isBack];
}

- (instancetype)initWithTitle:(NSString *)title fontSize:(CGFloat)fontSize image:(UIImage *)image target:(id)target action:(SEL)action isBack:(BOOL)isBack
{
    title = title ? [@" " stringByAppendingString:title] : @" ";
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 72, 44)];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    
    
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
    btn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [btn setTitleColor:[UIColor colorWithRed:0x07 / 255.0 green:0x6e / 255.0 blue:0xe4 / 255.0 alpha:1.0] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    
    if (image != nil) {
        [btn setImage:image forState:UIControlStateNormal];
        [btn setImage:image forState:UIControlStateHighlighted];
    }
    
    if (isBack) {
        UIImage *image = [UIImage imageNamed:@"nav-btn-back"];
        
        [btn setImage:image forState:UIControlStateNormal];
        [btn setImage:image forState:UIControlStateHighlighted];
        //[btn setBackgroundImage:image forState:UIControlStateNormal];
        //[btn setBackgroundImage:image forState:UIControlStateHighlighted];
    }
    
    //[btn sizeToFit];
    //[btn sizeThatFits:CGSizeMake(100, 40)];
    
        
    return [self initWithCustomView:btn];
}

@end
