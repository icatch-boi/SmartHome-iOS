// SHSetupWiFiCell.m

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
 
 // Created by zj on 2018/4/20 上午10:38.
    

#import "SHSetupWiFiCell.h"

@interface SHSetupWiFiCell () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;

@end

@implementation SHSetupWiFiCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    [self setupGUI];
}

- (void)setupGUI {
    _ssidLabel.text = NSLocalizedString(@"kWifiSSID", nil);
    _ssidTextField.placeholder = NSLocalizedString(@"kWifiSSIDInfo", nil);
    _passwordLabel.text = NSLocalizedString(@"kWifiPassword", nil);
    _passwordTextField.placeholder = NSLocalizedString(@"kWifiPasswordInfo", nil);
    
    _ssidTextField.delegate = self;
    _passwordTextField.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)showPasswordAction:(UIButton *)sender {
    _passwordTextField.secureTextEntry = !_passwordTextField.secureTextEntry;
    
    NSString *imageName = _passwordTextField.secureTextEntry ? @"ic_visibility_off_18dp" : @"ic_visibility_18dp";
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];
}

#pragma mark - UITextFiledDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
