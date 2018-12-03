//
//  ZJSlidingDrawerViewController.m
//  SlidingDrawer
//
//  Created by zj on 2018/5/13.
//  Copyright © 2018年 zj. All rights reserved.
//

#import "ZJSlidingDrawerViewController.h"
#import "LoginCommonHeader.h"
#import "SHNetworkManager.h"
#import "SHUserAccount.h"
@interface ZJSlidingDrawerViewController () <SHLoginFirstViewDelegate>

@property (nonatomic, assign) CGFloat slideSacle;
@property (nonatomic, strong, readwrite) UIViewController *mainVC;
@property (nonatomic, strong) UIViewController *leftMenuVC;
@property (nonatomic, strong) UIViewController *showingVC;

@property (nonatomic, strong) UIButton *coverButton;

@property (nonatomic, strong) SHLoginFirstView *loginFirstView;

@end

@implementation ZJSlidingDrawerViewController

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

+ (instancetype)sharedSlidingDrawerVC {
    return (ZJSlidingDrawerViewController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
}

+ (instancetype)slidingDrawerVCWithMainVC:(UIViewController *)mainVC leftMenuVC:(UIViewController *)leftMenuVC slideScale:(CGFloat)slideScale {
    ZJSlidingDrawerViewController *drawerVC = [[ZJSlidingDrawerViewController alloc] init];
    
    drawerVC.mainVC = mainVC;
    drawerVC.slideSacle = slideScale;
    drawerVC.leftMenuVC = leftMenuVC;
    
    [drawerVC.view addSubview:leftMenuVC.view];
    [drawerVC.view addSubview:mainVC.view];
    
    [drawerVC addChildViewController:leftMenuVC];
    [drawerVC addChildViewController:mainVC];
    
    return drawerVC;
}

- (void)openLeftMenu {
    [self.leftMenuVC.view setNeedsLayout];
    [self.mainVC.view addSubview:self.coverButton];

    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.mainVC.view.transform = CGAffineTransformMakeTranslation(kScreenWidth * self.slideSacle, 0);
        self.leftMenuVC.view.transform = CGAffineTransformIdentity;
        
    } completion:^(BOOL finished) {
//        [self.mainVC.view addSubview:self.coverButton];
    }];
}

- (void)closeLeftMenu {
    [self coverButtonClick];
}

- (void)pushViewController:(UIViewController *)destVC {
    if (_showingVC != nil) {
        return;
    }
    
    if (![destVC isKindOfClass:[UINavigationController class]]) {
        destVC = [[UINavigationController alloc] initWithRootViewController:destVC];
    }
    
    destVC.view.frame = self.mainVC.view.bounds;
    destVC.view.transform = self.mainVC.view.transform;
    
    [self.view addSubview:destVC.view];
    [self addChildViewController:destVC];
    
    self.showingVC = destVC;
    self.showingVC.view.transform = CGAffineTransformMakeTranslation(self.mainVC.view.frame.size.width, 0);
    
//    [self coverButtonClick];
    // 以动画形式
    [UIView animateWithDuration:0.25 animations:^{
        destVC.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)popViewController {
    [UIView animateWithDuration:0.25 animations:^{
        self.showingVC.view.transform = CGAffineTransformMakeTranslation(self.mainVC.view.frame.size.width, 0);
    } completion:^(BOOL finished) {
        [self.showingVC removeFromParentViewController];
        [self.showingVC.view removeFromSuperview];
        self.showingVC = nil;
    }];
}

// MARK: - view
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.leftMenuVC.view.transform = CGAffineTransformMakeTranslation(-kScreenWidth * self.slideSacle, 0);
    [self setupGUI];
    
    [self addLoginObserver];
}

- (void)setupGUI {
    self.mainVC.view.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.mainVC.view.layer.shadowOffset = CGSizeMake(3, 3);
    self.mainVC.view.layer.shadowOpacity = 0.5;
    self.mainVC.view.layer.shadowRadius = 5;
    
    for (UIViewController *childVC in self.mainVC.childViewControllers) {
        [self addEdgePanGestureRecognizerToView:childVC.view];
    }
}

- (void)addEdgePanGestureRecognizerToView:(UIView *)view {
    UIScreenEdgePanGestureRecognizer *pan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(edgePanGestureRecognizer:)];
    pan.edges = UIRectEdgeLeft;
    
    [view addGestureRecognizer:pan];
}

- (void)edgePanGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)pan {
//    NSLog(@"edgePanGestureRecognizer");
    
    CGFloat offsetX = [pan translationInView:pan.view].x;
    
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (self.mainVC.view.frame.origin.x > kScreenWidth * 0.5) {
            [self openLeftMenu];
        } else {
            [self coverButtonClick];
        }
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        offsetX = (offsetX > kScreenWidth * _slideSacle) ? kScreenWidth * _slideSacle : offsetX;
        self.mainVC.view.transform = CGAffineTransformMakeTranslation(offsetX, 0);
        self.leftMenuVC.view.transform = CGAffineTransformMakeTranslation(-kScreenWidth * self.slideSacle + offsetX, 0);
    }
}

- (void)panGestureRecognizer:(UIPanGestureRecognizer *)pan {
    CGFloat offsetX = [pan translationInView:pan.view].x;

//    NSLog(@"offsetX = %f", offsetX);
    if (offsetX > 0) {
        return;
    }
    
    CGFloat distance = kScreenWidth * self.slideSacle + offsetX;
    if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (self.mainVC.view.frame.origin.x > kScreenWidth * 0.5) {
            [self openLeftMenu];
        } else {
            [self coverButtonClick];
        }
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        self.mainVC.view.transform = CGAffineTransformMakeTranslation(MAX(distance, 0), 0);
        self.leftMenuVC.view.transform = CGAffineTransformMakeTranslation(-kScreenWidth * self.slideSacle + distance, 0);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
- (UIButton *)coverButton {
    if (_coverButton == nil) {
        _coverButton = [[UIButton alloc] init];
        _coverButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        _coverButton.frame = self.mainVC.view.bounds;
        [_coverButton addTarget:self action:@selector(coverButtonClick) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizer:)];
        [_coverButton addGestureRecognizer:pan];
    }
    
    return _coverButton;
}

- (void)coverButtonClick {
    [self.coverButton removeFromSuperview];

    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        self.mainVC.view.transform = CGAffineTransformIdentity;
        self.leftMenuVC.view.transform = CGAffineTransformMakeTranslation(-kScreenWidth * self.slideSacle, 0);
    } completion:^(BOOL finished) {
        self.coverButton = nil;
    }];
}

// MARK: - login
- (void)addLoginObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLogin) name:kUserShouldLoginNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reLogin) name:reloginNotifyName object:nil];
}

- (void)userLogin {
    SHLoginFirstView *view = self.loginFirstView;
    [UIView animateWithDuration:0.25 animations:^{
        [self.view addSubview:view];
    }];
}

- (void)reLogin {
    [[SHCameraManager sharedCameraManger] unmappingAllCamera];
    [[SHNetworkManager sharedNetworkManager].userAccount deleteUserAccount];
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:/*@"Tips"*/NSLocalizedString(@"Tips", nil) message:/*@"Account login is invalid, please login again."*/NSLocalizedString(@"kLoginInvalid", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"OK"*/NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self userLogin];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
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
    
    [self pushViewController:nav];
#if 0
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:nav animated:YES completion:^{
            [self closeLoginFirstView];
        }];
    });
#endif
}

- (void)signinAccountHandle {
    SHLoginViewController *vc = [SHLoginViewController loginViewController];
    
    [self pushViewController:vc];
#if 0
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:vc animated:YES completion:^{
            [self closeLoginFirstView];
        }];
    });
#endif
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
