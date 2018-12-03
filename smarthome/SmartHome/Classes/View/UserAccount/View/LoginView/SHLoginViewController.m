// SHLoginViewController.m

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
 
 // Created by zj on 2018/5/19 上午10:22.
    

#import "SHLoginViewController.h"
#import "SHUserAccountCell.h"
#import "SHLogonViewController.h"
#import "SHNetworkManagerHeader.h"
#import "ZJSlidingDrawerViewController.h"
#import "SHMainViewController.h"
#import "UnderLineTextField.h"

static const CGFloat kBottomDefaultValue = 80;

@interface SHLoginViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *signinButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *signinBtnBottomCons;

@property (weak, nonatomic) IBOutlet UnderLineTextField *emailTextField;
@property (weak, nonatomic) IBOutlet UnderLineTextField *pwdTextField;

@property (weak, nonatomic) IBOutlet UIButton *forgotPWDBtn;
@property (weak, nonatomic) IBOutlet UIButton *signupBtn;
@property (weak, nonatomic) IBOutlet UILabel *accountInfoLabel;

@property (nonatomic, weak) MBProgressHUD *progressHUD;

@end

@implementation SHLoginViewController

+ (instancetype)loginViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"UserAccount" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"LoginViewControllerID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
    [self setupLocalizedString];

    _signinBtnBottomCons.constant = kBottomDefaultValue * kScreenHeightScale;
    
    [_signinButton setCornerWithRadius:_signinButton.bounds.size.height * 0.25 masksToBounds:NO];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil target:self action:@selector(close) isBack:YES];
    
    _emailTextField.delegate = self;
    _pwdTextField.delegate = self;
    
    UIColor *color = [UIColor ic_colorWithHex:kButtonThemeColor];
    _emailTextField.lineColor = color;
    _pwdTextField.lineColor = color;
    
    // FIXME: - debug
//    _emailTextField.text = @"cj787696506@163.com";
//    _pwdTextField.text = @"1234567890";
    
    [self setSigninButtonColor];
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[UIImage imageNamed:@"nav-logo"] gradient:NO];
    [self addLineForForgotPWDBtn];
    [self addLineForSignupBtn];
    
   _emailTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAccounts];
    _accountInfoLabel.textColor = [UIColor ic_colorWithHex:kTextThemeColor];
}

- (void)setupLocalizedString {
    [_signinButton setTitle:NSLocalizedString(@"kLogin", nil) forState:UIControlStateNormal];
    [_signinButton setTitle:NSLocalizedString(@"kLogin", nil) forState:UIControlStateHighlighted];
    [_forgotPWDBtn setTitle:NSLocalizedString(@"kForgotPassword", nil) forState:UIControlStateNormal];
    [_forgotPWDBtn setTitle:NSLocalizedString(@"kForgotPassword", nil) forState:UIControlStateHighlighted];
    [_signupBtn setTitle:NSLocalizedString(@"kSignup", nil) forState:UIControlStateNormal];
    [_signupBtn setTitle:NSLocalizedString(@"kSignup", nil) forState:UIControlStateHighlighted];
    
    _emailTextField.placeholder = NSLocalizedString(@"kEmail", nil);
    _pwdTextField.placeholder = NSLocalizedString(@"kPassword", nil);
    _accountInfoLabel.text = NSLocalizedString(@"kDonotHaveAccount", nil);
    
    [_forgotPWDBtn layoutIfNeeded];
    [_signupBtn layoutIfNeeded];
}

- (void)addLineForForgotPWDBtn {
    [_forgotPWDBtn setTintColor:[UIColor ic_colorWithHex:kTextThemeColor]];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, _forgotPWDBtn.frame.size.height - 2, _forgotPWDBtn.frame.size.width, 1)];
    line.backgroundColor = _forgotPWDBtn.currentTitleColor;
    
    [_forgotPWDBtn addSubview:line];
}

- (void)addLineForSignupBtn {
    [_signupBtn setTintColor:[UIColor ic_colorWithHex:kTextThemeColor]];

    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, _signupBtn.frame.size.height - 2, _signupBtn.frame.size.width, 1)];
    line.backgroundColor = _signupBtn.currentTitleColor;
    
    [_signupBtn addSubview:line];
}

- (void)setSigninButtonColor {
#if 0
    uint32_t colorValue = ![_emailTextField.text isEqualToString:@""] && ![_pwdTextField.text isEqualToString:@""] ? kButtonThemeColor : kButtonDefaultColor;
    _signinButton.backgroundColor = [UIColor ic_colorWithHex:colorValue];
#else
    _signinButton.enabled = ![_emailTextField.text isEqualToString:@""] && ![_pwdTextField.text isEqualToString:@""];
#endif
}

- (void)close {
    [_emailTextField resignFirstResponder];
    [_pwdTextField resignFirstResponder];
//    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] popViewController];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)showPasswordClick:(id)sender {
    _pwdTextField.secureTextEntry = !_pwdTextField.secureTextEntry;
    
    NSString *imageName = _pwdTextField.secureTextEntry ? @"ic_visibility_off_18dp" : @"ic_visibility_18dp";
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];
}

- (IBAction)loginClick {
    [_emailTextField resignFirstResponder];
    [_pwdTextField resignFirstResponder];
    __block NSRange emailRange;
    __block NSRange passwordRange;
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:/*@"正在登录..."*/NSLocalizedString(@"kLogining", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            emailRange = [_emailTextField.text rangeOfString:@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}" options:NSRegularExpressionSearch];
            passwordRange = [_pwdTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,16}" options:NSRegularExpressionSearch];
        });
        
        if (emailRange.location == NSNotFound || passwordRange.location == NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:/*@"输入的邮箱或密码无效，请重新输入"*/NSLocalizedString(@"kInvalidEmailOrPassword", nil) preferredStyle:UIAlertControllerStyleAlert];
                [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertC animated:YES completion:nil];
            });
        } else {
            __block NSString *email = nil;
            __block NSString *password = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                email = _emailTextField.text;
                password = _pwdTextField.text;
            });
            
            WEAK_SELF(self);
            [[SHNetworkManager sharedNetworkManager] loadAccessTokenByEmail:email password:password completion:^(BOOL isSuccess, id result) {
                SHLogInfo(SHLogTagAPP, @"load accessToken is success: %d", isSuccess);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isSuccess) {
                        [weakself.progressHUD hideProgressHUD:YES];
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotification object:nil];
                        [weakself close];
                        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] closeLoginFirstView];
                    } else {
                        Error *error = result;
                        SHLogError(SHLogTagAPP, @"loadAccessTokenByEmail is failed, error: %@", error.error_description);
                        
                        weakself.progressHUD.detailsLabelText = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]; //error.error_description;
                        NSString *notice = NSLocalizedString(@"kLoginFailed", nil); //@"登录失败";
                        [weakself.progressHUD showProgressHUDNotice:notice showTime:2.0];
                    }
                });
            }];
        }
    });
}

- (IBAction)forgotPWDClick {
    SHLogTRACE();
    
    [self close];

#if 0
    SHMainViewController *mainVC = (SHMainViewController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    [mainVC signupAccountHandleWithEmail:_emailTextField.text isResetPWD:YES];
#else
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] signupAccountHandleWithEmail:_emailTextField.text isResetPWD:YES];
    });
#endif
}

- (IBAction)signupClick:(id)sender {
    [self close];
    
//    SHLogonViewController *vc = [SHLogonViewController logonViewController];
//
//    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC presentViewController:vc animated:YES completion:nil];
#if 0
    SHMainViewController *mainVC = (SHMainViewController *)[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC;
    [mainVC signupAccountHandleWithEmail:_emailTextField.text isResetPWD:NO];
#else
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] signupAccountHandleWithEmail:_emailTextField.text isResetPWD:NO];
    });
#endif
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];

    [self setSigninButtonColor];
    
    return YES;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
