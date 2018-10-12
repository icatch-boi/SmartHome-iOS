//
//  GuideView.h
//  GuideDemo
//
//  Created by 李剑钊 on 15/7/23.
//  Copyright (c) 2015年 sunli. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol GuideViewDismissDelegate <NSObject>
- (void)onGuideViewDismiss;
@end
@interface GuideView : UIView

@property (nonatomic,weak) id<GuideViewDismissDelegate> dismissDelegate;
- (void)showInView:(UIView *)view maskBtn:(UIButton *)btn;
- (void)dismissView;
@end
