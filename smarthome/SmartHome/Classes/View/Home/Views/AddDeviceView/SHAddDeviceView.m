// SHAddDeviceView.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
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
 
 // Created by zj on 2019/7/3 5:33 PM.
    

#import "SHAddDeviceView.h"

@interface SHAddDeviceView ()

@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *addDeviceBtn;

@end

@implementation SHAddDeviceView

+ (instancetype)addDeviceViewWithFrame:(CGRect)frame {
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([self class]) bundle:nil];
    SHAddDeviceView *view = [[nib instantiateWithOwner:nil options:nil] firstObject];
    view.frame = frame;
    return view;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [_addDeviceBtn setCornerWithRadius:5.0 masksToBounds:NO];
    [_addDeviceBtn setBorderWidth:1.0 borderColor:[UIColor ic_colorWithHex:kThemeColor]];
    [_addDeviceBtn setTitleColor:[UIColor ic_colorWithHex:kThemeColor] forState:UIControlStateNormal];
    [_addDeviceBtn setTitleColor:[UIColor ic_colorWithHex:kThemeColor alpha:0.618] forState:UIControlStateHighlighted];
    [_addDeviceBtn setTitle:[@" " stringByAppendingString:NSLocalizedString(@"kAddDevice", nil)] forState:UIControlStateNormal];

    _tipsLabel.textColor = [UIColor ic_colorWithHex:kTextColor];
    _tipsLabel.text = NSLocalizedString(@"kAddDeviceTips", nil);
    
    self.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
}

- (IBAction)addDeviceClick:(id)sender {
    if (self.addDeviceHandle) {
        self.addDeviceHandle();
    }
}

@end
