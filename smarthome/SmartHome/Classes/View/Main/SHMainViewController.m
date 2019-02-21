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
#import "SHLogonViewController.h"
#import "SHNetworkManagerHeader.h"
#import "SHLoginFirstView.h"
#import "SHLoginViewController.h"

@interface SHMainViewController () <SHLoginFirstViewDelegate>

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
    [SHTool configureAppThemeWithController:self];
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
