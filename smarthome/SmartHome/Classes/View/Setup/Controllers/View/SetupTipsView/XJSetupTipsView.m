// XJSetupTipsView.m

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
 
 // Created by zj on 2018/5/21 上午11:26.
    
static const CGFloat kWidthDefaultValue = 180;
static const CGFloat kHeightDefaultValue = 180;

#import "XJSetupTipsView.h"

@interface XJSetupTipsView ()

@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewWidthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewHeightCons;
@property (weak, nonatomic) IBOutlet UIImageView *gifImageView;

@end

@implementation XJSetupTipsView

+ (instancetype)setupTipsView {
    UINib *nib = [UINib nibWithNibName:@"XJSetupTipsView" bundle:nil];
    return [nib instantiateWithOwner:nil options:nil][0];
}

- (IBAction)nextClick:(id)sender {
    SHLogTRACE();
    if ([self.delegate respondsToSelector:@selector(closeTipsView:)]) {
        [self.delegate closeTipsView:self];
    }
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupGUI];
}

- (void)setupGUI {
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.25 masksToBounds:NO];
    
    _tipsViewWidthCons.constant = kWidthDefaultValue * kScreenHeightScale;
    _tipsViewHeightCons.constant = kHeightDefaultValue * kScreenHeightScale;
    
    _gifImageView.image = [UIImage animatedImageNamed:@"gif_" duration:0.65];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
