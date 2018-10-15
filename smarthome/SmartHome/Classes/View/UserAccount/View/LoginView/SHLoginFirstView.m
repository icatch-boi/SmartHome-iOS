// SHLoginFirstView.m

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
 
 // Created by zj on 2018/5/19 上午9:36.
    

#import "SHLoginFirstView.h"

static const CGFloat kBottomConsDefaultValue = 60;
static const CGFloat kLogoTopConsDefaultVaule = 80;

@interface SHLoginFirstView ()

@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoTopCons;

@end

@implementation SHLoginFirstView

+ (instancetype)loginFirstView {
    UINib *nib = [UINib nibWithNibName:@"SHLoginFirstView" bundle:nil];
    
    SHLoginFirstView *view = [nib instantiateWithOwner:nil options:nil][0];
    view.frame = [[UIScreen mainScreen] bounds];

    view.bottomCons.constant = kBottomConsDefaultValue * kScreenHeightScale;
    view.logoTopCons.constant = kLogoTopConsDefaultVaule * kScreenWidthScale;
    
    return view;
}

- (IBAction)signupAction {
    if ([self.delegate respondsToSelector:@selector(signupAccount:)]) {
        [self.delegate signupAccount:self];
    }
}

- (IBAction)signinAction {
    if ([self.delegate respondsToSelector:@selector(signinAccount:)]) {
        [self.delegate signinAccount:self];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
