//
//  SHUserAccountCell.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/3/5.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHUserAccountCell.h"

@interface SHUserAccountCell () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UILabel *surepwdLabel;

@end

@implementation SHUserAccountCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    [self setupGUI];
}

- (void)setupGUI {
    _emailTextField.delegate = self;
    _pwdTextField.delegate = self;
    _surepwdTextField.delegate = self;
    _verifycodeTextField.delegate = self;
    
    [_getVerifycodeBtn setCornerWithRadius:_getVerifycodeBtn.bounds.size.height * 0.25 masksToBounds:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)showpasswordClick:(UIButton *)sender {
    UITextField *textField = _pwdTextField ? _pwdTextField : _surepwdTextField;
    textField.secureTextEntry = !textField.secureTextEntry;
    
    NSString *imageName = textField.secureTextEntry ? @"ic_visibility_off_18dp" : @"ic_visibility_18dp";
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];
}

- (IBAction)getVerifycodeClick:(id)sender {
    SHLogTRACE();
    if([self.delegate respondsToSelector:@selector(sendCheckEmailValidCommand)]) {
        [self.delegate sendCheckEmailValidCommand];
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

@end
