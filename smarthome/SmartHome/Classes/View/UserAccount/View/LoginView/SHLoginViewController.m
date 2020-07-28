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

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kEnterAPMode];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [self addGestureOperation];
    [self noNeedExitAppHandle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noNeedExitAppHandle) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)noNeedExitAppHandle {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kEnterAPMode];
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
    
    [self setSigninButtonColor];
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[[UIImage imageNamed:@"nav-logo"] imageWithTintColor:[UIColor whiteColor]]  gradient:NO];
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
    _signinButton.enabled = ![_emailTextField.text isEqualToString:@""] && ![_pwdTextField.text isEqualToString:@""];
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

    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLogining", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if (![self isValidInput]) {
            SHLogWarn(SHLogTagAPP, @"Input content invalid.");
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
                        NSString *notice = NSLocalizedString(@"kLoginFailed", nil);
                        [weakself.progressHUD showProgressHUDNotice:notice showTime:2.0];
                    }
                });
            }];
        }
    });
}

- (BOOL)isValidInput {
    __block BOOL valid = YES;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSRange emailRange = [_emailTextField.text rangeOfString:[NSString stringWithFormat:@"%@|%@", kPhoneRegularExpression, kEmailRegularExpression] options:NSRegularExpressionSearch];
        
        if (emailRange.location == NSNotFound) {
            [self showTipsWithInfo:[NSString stringWithFormat:NSLocalizedString(@"kInvalidEmailOrPassword", nil), kPasswordMinLength, kPasswordMaxLength]];
            
            valid = NO;
            SHLogError(SHLogTagAPP, @"Input email invalid.");
            return;
        }
        
        if (![SHTool isValidPassword:_pwdTextField.text]) {
            [self showTipsWithInfo:[NSString stringWithFormat:NSLocalizedString(@"kAccountPasswordDes", nil), kPasswordMinLength, kPasswordMaxLength]];
            
            valid = NO;
            SHLogError(SHLogTagAPP, @"Input password invalid.");
            return;
        }
    });
    
    return valid;
}

- (void)showTipsWithInfo:(NSString *)info {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
        
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:info preferredStyle:UIAlertControllerStyleAlert];
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alertC animated:YES completion:nil];
    });
}

- (IBAction)forgotPWDClick {
    SHLogTRACE();
    
    [self close];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] signupAccountHandleWithEmail:_emailTextField.text isResetPWD:YES];
    });
}

- (IBAction)signupClick:(id)sender {
    [self close];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.26 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] signupAccountHandleWithEmail:_emailTextField.text isResetPWD:NO];
    });
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.emailTextField) {
        [self.pwdTextField becomeFirstResponder];
    } else if (textField == self.pwdTextField) {
        [self loginClick];
    }
    
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

- (void)addGestureOperation  {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandle)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)tapGestureHandle {
    [self.view endEditing:YES];
}

@end
