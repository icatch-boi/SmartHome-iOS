//
//  BadgeButton.h
//  buttonTest
//
//  Created by ZJ on 2017/8/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgeButton : UIButton

@property (nonatomic) NSInteger badgeValue;
@property (nonatomic, assign) BOOL isRedBall;
@property (nonatomic, strong, readonly) UILabel *badgeLab;
- (void)setSubFrame;
@end
