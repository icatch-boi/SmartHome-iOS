// SHMainViewController.m

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
 
 // Created by zj on 2018/3/22 上午11:40.
    

#import "SHMainViewController.h"
#import "SHLoginView.h"
#import "SHLogonViewController.h"
#import "SHNetworkManagerHeader.h"
#import "SHLoginFirstView.h"
#import "SHLoginViewController.h"

@interface SHMainViewController () <SHLoginViewDelegate, SHLoginFirstViewDelegate>

@property (nonatomic, strong) SHLoginView *loginView;
@property (nonatomic, weak) MBProgressHUD *progressHUD;
@property (nonatomic, strong) SHLoginFirstView *loginFirstView;

@end

@implementation SHMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogin) name:kUserShouldLoginNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reLogin) name:reloginNotifyName object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGUI {
#if 0
    // set toolbar
    [self setToolbarHidden:NO];
    self.toolbar.barTintColor = [UIColor ic_colorWithHex:kThemeColor];
#endif
    self.navigationBar.barTintColor = [UIColor ic_colorWithHex:kThemeColor];
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = [UIColor whiteColor];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.childViewControllers.count > 0) {
        viewController.hidesBottomBarWhenPushed = YES;
    }
    
    [super pushViewController:viewController animated:animated];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)userLogin {
#if 0
    SHLoginView *view = self.loginView;
    
    [UIView animateWithDuration:0.25 animations:^{
        [self.view addSubview:view];
    }];
#endif
    SHLoginFirstView *view = self.loginFirstView;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view addSubview:view];
    }];
}

- (void)reLogin {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Account login is invalid, please login again." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self userLogin];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - loginView
- (SHLoginView *)loginView {
    if (_loginView == nil) {
        _loginView = [SHLoginView loginView];
        _loginView.delegate = self;
        _loginView.yConstraint.constant = -30;
    }
    
    return _loginView;
}

- (void)closeLoginView {
    [_loginView removeFromSuperview];
    _loginView = nil;
}

- (void)logonAccount:(SHLoginView *)loginView {
    SHLogonViewController *vc = [SHLogonViewController logonViewController];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self pushViewController:vc animated:YES];
        [self presentViewController:nav animated:YES completion:^{
            [self.loginView removeFromSuperview];
        }];
    });
}

- (void)loginAccount:(SHLoginView *)loginView {
    [self.loginView.emailTextField resignFirstResponder];
    [self.loginView.pwdTextField resignFirstResponder];
    __block NSRange emailRange;
    __block NSRange passwordRange;
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:@"正在登录..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            emailRange = [self.loginView.emailTextField.text rangeOfString:@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}" options:NSRegularExpressionSearch];
            passwordRange = [self.loginView.pwdTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,16}" options:NSRegularExpressionSearch];
        });
        
        if (emailRange.location == NSNotFound || passwordRange.location == NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"输入的邮箱或密码无效，请重新输入" preferredStyle:UIAlertControllerStyleAlert];
                [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertC animated:YES completion:nil];
            });
        } else {
            __block NSString *email = nil;
            __block NSString *password = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                email = self.loginView.emailTextField.text;
                password = self.loginView.pwdTextField.text;
            });
            
            WEAK_SELF(self);
            [[SHNetworkManager sharedNetworkManager] loadAccessTokenByEmail:email password:password completion:^(BOOL isSuccess, id result) {
                SHLogInfo(SHLogTagAPP, @"load accessToken is success: %d", isSuccess);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (isSuccess) {
                        [weakself.progressHUD hideProgressHUD:YES];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kLoginSuccessNotification object:nil];
                        [weakself closeLoginView];
                    } else {
                        Error *error = result;
                        
                        weakself.progressHUD.detailsLabelText = error.error_description;
                        NSString *notice = @"登录失败";
                        [weakself.progressHUD showProgressHUDNotice:notice showTime:1.5];
                    }
                });
            }];
        }
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}

#pragma mark - LoginFirstView
- (SHLoginFirstView *)loginFirstView {
    if (_loginFirstView == nil) {
        _loginFirstView = [SHLoginFirstView loginFirstView];
        _loginFirstView.delegate = self;
    }
    
    return _loginFirstView;
}

- (void)closeLoginFirstView {
    [self.loginFirstView removeFromSuperview];
    _loginFirstView = nil;
}

- (void)signupAccount:(SHLoginFirstView *)view {
    SHLogTRACE();

    [self signupAccountHandleWithEmail:nil isResetPWD:NO];
}

- (void)signinAccount:(SHLoginFirstView *)view {
    SHLogTRACE();
 
    [self signinAccountHandle];
}

#pragma mark -
- (void)signupAccountHandleWithEmail:(NSString *)email isResetPWD:(BOOL)reset {
    UINavigationController *nav = (UINavigationController *)[SHLogonViewController logonViewController];
    SHLogonViewController *vc = (SHLogonViewController *)nav.topViewController;
    vc.email = email;
    vc.resetPWD = reset;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:nav animated:YES completion:^{
            [self closeLoginFirstView];
        }];
    });
}

- (void)signinAccountHandle {
    SHLoginViewController *vc = [SHLoginViewController loginViewController];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:vc animated:YES completion:^{
            [self closeLoginFirstView];
        }];
    });
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
