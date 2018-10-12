//
//  UnderLineTextField.h
//  UnderLinerTextField
//
//  Created by ZJ on 2018/5/23.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UnderLineTextField : UITextField

@property (nonatomic, strong) UIColor *lineColor;  // default blueColor
@property (nonatomic, assign) CGFloat lineWidth;   // default 1.0

@end
