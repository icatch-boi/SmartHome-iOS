// XJSetupScanTipsView.m

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
 
 // Created by zj on 2018/6/7 下午1:37.
    

#import "XJSetupScanTipsView.h"

static const CGFloat kMarginDefaultValue = 2;
static const CGFloat kTipsViewDefaultHeight = 120;
static const CGFloat kQRViewDefaultHeight = 90;
static const CGFloat kQRBottomDefaultValue = 12;

@interface XJSetupScanTipsView ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewTopMarginCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewHeightCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewBottomMarginCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qrViewTopCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *qrViewHeightCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nextButtonBottomCons;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *scanQRCodeDeviceLabel;
@property (weak, nonatomic) IBOutlet UILabel *scanQRCodeShareLabel;

@end

@implementation XJSetupScanTipsView

+ (instancetype)setupScanTipsView {
    UINib *nib = [UINib nibWithNibName:@"XJSetupScanTipsView" bundle:nil];
    return [nib instantiateWithOwner:nil options:nil][0];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupLocalizedString];
    [self setupGUI];
}

- (void)setupGUI {
    _tipsViewTopMarginCons.constant = _tipsViewBottomMarginCons.constant = _qrViewTopCons.constant = kMarginDefaultValue * kScreenHeightScale;
    _tipsViewHeightCons.constant = kTipsViewDefaultHeight * kScreenHeightScale;
    _qrViewHeightCons.constant = kQRViewDefaultHeight * kScreenHeightScale;
    _nextButtonBottomCons.constant = kQRBottomDefaultValue * kScreenHeightScale;
    
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.25 masksToBounds:NO];
}

- (IBAction)nextClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(closeScanTipsView:)]) {
        [self.delegate closeScanTipsView:self];
    }
}

- (IBAction)closeClick:(id)sender {
    [self nextClick:nil];
}

- (void)setupLocalizedString {
    _tipsLabel.text = NSLocalizedString(@"Tips", nil);
    _scanQRCodeDeviceLabel.text = NSLocalizedString(@"kDeviceScanQRCodeDes", nil);
    _scanQRCodeShareLabel.text = NSLocalizedString(@"kShareScanQRCodeDes", nil);
    [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateNormal];
    [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateHighlighted];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
