//
//  SHLoginView.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/3/5.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SHLoginView;
@protocol SHLoginViewDelegate <NSObject>

- (void)loginAccount:(SHLoginView *)loginView;
- (void)logonAccount:(SHLoginView *)loginView;

@end

@interface SHLoginView : UIView

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *yConstraint;

@property (weak, nonatomic) UITextField *emailTextField;
@property (weak, nonatomic) UITextField *pwdTextField;

@property (nonatomic, weak) id <SHLoginViewDelegate> delegate;

+ (instancetype)loginView;

@end
