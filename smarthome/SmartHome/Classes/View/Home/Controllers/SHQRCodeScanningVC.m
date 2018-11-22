//
//  SHQRCodeScanningVC.m
//  SmartHome
//
//  Created by ZJ on 2017/4/13.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHQRCodeScanningVC.h"
#import "XJSetupWiFiVC.h"
#import "XJSetupDeviceInfoVC.h"
#import "XJSetupTipsView.h"
#import "XJSetupScanTipsView.h"
#import "SHNetworkManagerHeader.h"
#import "Reachability.h"

static const CGFloat kTipsViewWidth = UIScreen.screenWidth * 0.85;
static const CGFloat kTipsViewHeight = UIScreen.screenHeight * 0.8;

@interface SHQRCodeScanningVC () <XJSetupTipsViewDelegate, XJSetupScanTipsViewDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) UIView *coverView;
@property (nonatomic, strong) XJSetupTipsView *tipsView;
@property (nonatomic, strong) XJSetupScanTipsView *scanTipsView;

@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, weak) UIPageControl *pageControl;

@end

@implementation SHQRCodeScanningVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 注册观察者
    [SGQRCodeNotificationCenter addObserver:self selector:@selector(SGQRCodeInformationFromeAibum:) name:SGQRCodeInformationFromeAibum object:nil];
    [SGQRCodeNotificationCenter addObserver:self selector:@selector(SGQRCodeInformationFromeScanning:) name:SGQRCodeInformationFromeScanning object:nil];
    
    [self setupGUI];
}

- (void)setupGUI {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(close) isBack:NO];
    
    [self.navigationController.view addSubview:[self coverView]];
    _coverView ? [self addTapGesture] : void();
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureHandle:)];
    [_coverView addGestureRecognizer:tap];
}

- (void)tapGestureHandle:(UITapGestureRecognizer *)tapGesture {
    SHLogTRACE();
    CGPoint point = [tapGesture locationInView:_coverView];
    UIView *subView = _coverView.subviews.firstObject;
    if (subView == nil) {
        SHLogError(SHLogTagAPP, @"subView is nil.");
        return;
    }
    
    if (!CGRectContainsPoint(subView.frame, point)) {
        [UIView animateWithDuration:0.25 animations:^{
            _coverView.alpha = 0;
        } completion:^(BOOL finished) {
            [subView removeFromSuperview];
            [self closeCoverView];
        }];
    }
}

- (void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (UIView *)coverView {
    if (_coverView) {
        return _coverView;
    }
    
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.screenWidth, UIScreen.screenHeight)];
    v.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    
    _coverView = v;

#if 0
    [self addTipsViewToCoverView];
#else
    [self setupScrollView];
    [self setupPageControl];
#endif
    
    return v;
}

- (void)closeCoverView {
    [self closeTipsView];
    [self closeScanTipsView];
    
    for (UIView *v in _coverView.subviews) {
        [v removeFromSuperview];
    }
    
    [_coverView removeFromSuperview];
    _coverView = nil;
}

#pragma mark - UIScrollView
- (void)setupScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, kTipsViewWidth, kTipsViewHeight)];
    scrollView.center = _coverView.center;
    scrollView.contentSize = CGSizeMake(kTipsViewWidth * 2, 0);
    scrollView.pagingEnabled = YES;
    scrollView.backgroundColor = [UIColor redColor];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.scrollEnabled = YES;
    scrollView.bounces = NO;
    
    [scrollView addSubview:self.tipsView];
    self.scanTipsView.frame = CGRectOffset(self.scanTipsView.frame, kTipsViewWidth, 0);
    [scrollView addSubview:self.scanTipsView];
    
    scrollView.delegate = self;
    
    [_coverView addSubview:scrollView];
}

- (void)setupPageControl {
    UIPageControl *pageControl = [[UIPageControl alloc] init];
    CGFloat width = 50;
    CGFloat height = 15;
    CGFloat x = (UIScreen.screenWidth - width) * 0.5;
    CGFloat y = UIScreen.screenHeight * 0.9 - height;
    pageControl.frame = CGRectMake(x, y, 50, 20);
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [ UIColor redColor];
    pageControl.numberOfPages = 2;
    pageControl.currentPage = 0;
    
    self.pageControl = pageControl;
    
    [_coverView addSubview:pageControl];
    [_coverView bringSubviewToFront:pageControl];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    offsetX += CGRectGetWidth(scrollView.frame) * 0.5;
    
    NSInteger page = offsetX / CGRectGetWidth(scrollView.frame);
    
    self.pageControl.currentPage = page;
}

#pragma mark - XJSetupTipsViewDelegate
- (void)closeTipsView:(XJSetupTipsView *)view {
    [UIView animateWithDuration:0.25 animations:^{
        _coverView.alpha = 0;
    } completion:^(BOOL finished) {
        [self closeTipsView];
        [self closeCoverView];
    }];
}

- (void)setupTipsViewNextClick:(XJSetupWiFiVC *)view {
    [self addScanTipsViewToCoverView];
    [self closeTipsView];
}

#pragma mark - XJSetupScanTipsViewDelegate
- (void)closeScanTipsView:(XJSetupScanTipsView *)view {
    [UIView animateWithDuration:0.25 animations:^{
        _coverView.alpha = 0;
    } completion:^(BOOL finished) {
        [self closeScanTipsView];
        [self closeCoverView];
    }];
}

#pragma mark - TipsView
- (XJSetupTipsView *)tipsView {
    if (_tipsView == nil) {
        _tipsView = [XJSetupTipsView setupTipsView];
        _tipsView.frame = CGRectMake(0, 0, kTipsViewWidth, kTipsViewHeight);
        
        _tipsView.delegate = self;
    }
    
    return _tipsView;
}

- (void)addTipsViewToCoverView {
    self.tipsView.center = _coverView.center;
    [_coverView addSubview:self.tipsView];
}

- (void)closeTipsView {
    if (_tipsView) {
        [_tipsView removeFromSuperview];
        _tipsView = nil;
    }
}

#pragma mark - ScanTipsView
- (XJSetupScanTipsView *)scanTipsView {
    if (_scanTipsView == nil) {
        _scanTipsView = [XJSetupScanTipsView setupScanTipsView];
        _scanTipsView.frame = CGRectMake(0, 0, kTipsViewWidth, kTipsViewHeight);
        
        _scanTipsView.delegate = self;
    }
    
    return _scanTipsView;
}

- (void)addScanTipsViewToCoverView {
    self.scanTipsView.center = _coverView.center;
    [_coverView addSubview:self.scanTipsView];
}

- (void)closeScanTipsView {
    if (_scanTipsView) {
        [_scanTipsView removeFromSuperview];
        _scanTipsView = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    SHLogDebug(SHLogTagAPP, @"%@ - dealloc", self.class);
    [SGQRCodeNotificationCenter removeObserver:self];
}

- (void)SGQRCodeInformationFromeAibum:(NSNotification *)noti {
    NSString *string = noti.object;
    
#if 0
    SHCameraInfoVC *jumpVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SHCameraInfoVCID"];
    jumpVC.managedObjectContext = _managedObjectContext;
    jumpVC.cameraUid = string;
    jumpVC.cameraName = string;
    [self.navigationController pushViewController:jumpVC animated:YES];
#else
#if 0
    if (_isStandardMode) {
        [self getCameraUIDWithCiphertext:string];

        SHSetupWiFiViewController *vc = [SHSetupWiFiViewController setupWiFiViewController];
        vc.managedObjectContext = _managedObjectContext;
        [self.navigationController pushViewController:vc animated:YES];
        
        return;
    }
    
    SHCameraInfoViewController *jumpVC = [[UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil] instantiateViewControllerWithIdentifier:@"SHCameraInfoViewControllerID"];
    jumpVC.managedObjectContext = _managedObjectContext;
    jumpVC.cameraUid = string;
    [self.navigationController pushViewController:jumpVC animated:YES];
#endif
    [self scanResultHandle:string];
#endif
}

- (void)SGQRCodeInformationFromeScanning:(NSNotification *)noti {
    SGQRCodeLog(@"noti - - %@", noti);
    NSString *string = noti.object;
    
#if 0
    SHCameraInfoVC *jumpVC = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"SHCameraInfoVCID"];
    jumpVC.managedObjectContext = _managedObjectContext;
    jumpVC.cameraUid = string;
    jumpVC.cameraName = string;
    [self.navigationController pushViewController:jumpVC animated:YES];
#else
#if 0
    if (_isStandardMode) {
        [self getCameraUIDWithCiphertext:string];
        
        SHSetupWiFiViewController *vc = [SHSetupWiFiViewController setupWiFiViewController];
        vc.managedObjectContext = _managedObjectContext;
        [self.navigationController pushViewController:vc animated:YES];

        return;
    }
    
    SHCameraInfoViewController *jumpVC = [[UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil] instantiateViewControllerWithIdentifier:@"SHCameraInfoViewControllerID"];
    jumpVC.managedObjectContext = _managedObjectContext;
    jumpVC.cameraUid = string;
    [self.navigationController pushViewController:jumpVC animated:YES];
#endif
    [self scanResultHandle:string];
#endif

//    if ([string hasPrefix:@"http"]) {
//        ScanSuccessJumpVC *jumpVC = [[ScanSuccessJumpVC alloc] init];
//        jumpVC.jump_URL = string;
//        [self.navigationController pushViewController:jumpVC animated:YES];
//        
//    } else { // 扫描结果为条形码
//        
//        ScanSuccessJumpVC *jumpVC = [[ScanSuccessJumpVC alloc] init];
//        jumpVC.jump_bar_code = string;
//        [self.navigationController pushViewController:jumpVC animated:YES];
//    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (NSString *)getCameraUIDWithCiphertext:(NSString *)ciphertext {
    int parseResult = 0;
    NSString *token = [[SHQRManager sharedQRManager] getTokenFromQRString:ciphertext parseResult:&parseResult];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (token == nil || uid == nil) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[self tipsInfoFromParseResult:parseResult] preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self viewWillAppear:YES];
            });
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
        
        return nil;
    } else {
        if ([uid containsString:@" "]) {
            UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:/*@"The uid contains Spaces, please check."*/NSLocalizedString(@"kDeviceUIDInvalid", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self viewWillAppear:YES];
                });
            }]];
            
            [self presentViewController:alertVC animated:YES completion:nil];
            
            return nil;
        } else {
//            [[NSUserDefaults standardUserDefaults] setObject:uid forKey:kCurrentAddCameraUID];
            if (![self checkDeviceExistsByUID:uid]) {
                [[NSUserDefaults standardUserDefaults] setObject:uid forKey:kCurrentAddCameraUID];
            }
            
            return uid;
        }
    }
}

- (NSString *)tipsInfoFromParseResult:(int)result {
    NSString *message = nil;
    
    switch (result) {
        case ICH_QR_VALID:
            message = NSLocalizedString(@"kQRCodeInvalidTipsDescription", nil); //@"无效二维码，请扫描机台上的二维码或APP内生成的分享二维码。"/*NSLocalizedString(@"kQRCodeInvalidTipsInfo", nil)*/;
            break;
            
        case ICH_QR_DIE:
            message = NSLocalizedString(@"kQRCodeFailureTipsInfo", nil);
            break;
            
        case ICH_QR_USEABORT:
            message = NSLocalizedString(@"kCameraFailureTipsInfo", nil);
            break;
            
        default:
            message = NSLocalizedString(@"kQRCodeReadException", @"");
            break;
    }
    
    return message;
}

- (NSDictionary *)parseJSONString:(NSString *)str {
    return [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
}

- (void)scanResultHandle:(NSString *)str {
    NSDictionary *dict = [self parseJSONString:str];
    
    dict ? [self shareQRCodeAddCamera:str] : [self standardModeAddCamera:str];
}

- (void)standardModeAddCamera:(NSString *)str {
#if 0
    [self getCameraUIDWithCiphertext:str];
    
    XJSetupWiFiVC *vc = [XJSetupWiFiVC setupWiFiVC];
    [self.navigationController pushViewController:vc animated:YES];
#else
    NSString *uid = [self getCameraUIDWithCiphertext:str];
    if (uid == nil || [self checkDeviceExistsByUID:uid]) {
        return;
    }
    
    [self checkNetworkStatus];
#endif
}

- (void)shareQRCodeAddCamera:(NSString *)str {
    NSDictionary *dict = [self parseJSONString:str];
    if ([self checkDeviceExistsByCameraID:dict[@"cameraId"]]) {
        return;
    }
    
    XJSetupDeviceInfoVC *jumpVC = [[UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil] instantiateViewControllerWithIdentifier:@"XJSetupDeviceInfoVCID"];
    [[NSUserDefaults standardUserDefaults] setObject:str forKey:kCurrentAddCameraUID];
    
    [self.navigationController pushViewController:jumpVC animated:YES];
}

- (BOOL)checkDeviceExistsByUID:(NSString *)uid {
    BOOL hasExist = NO;
    SHCameraObject *camObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:uid];
    
    if (camObj) {
        hasExist = YES;
        [self showDeviceExistAlertWithMessage:/*@"Device Already Exist."*/NSLocalizedString(@"kDeviceAlreadyExist", nil)];
    }
    
    return hasExist;
}

- (BOOL)checkDeviceExistsByCameraID:(NSString *)cameraID {
    BOOL hasExist = NO;
    
    for (SHCameraObject *obj in [SHCameraManager sharedCameraManger].smarthomeCams) {
        if ([obj.camera.id isEqualToString:cameraID]) {
            hasExist = YES;
            [self showDeviceExistAlertWithMessage:/*@"Device Already Exist."*/NSLocalizedString(@"kDeviceAlreadyExist", nil)];

            break;
        }
    }
    
    return hasExist;
}

- (void)showDeviceExistAlertWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:/*@"Tips"*/NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"OK"*/NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self viewWillAppear:YES];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.navigationController.view];
    }
    
    return _progressHUD;
}

#pragma mark - Check Network Reachable
- (void)checkNetworkStatus {
    NetworkStatus netStatus = [[Reachability reachabilityWithHostName:@"https://www.baidu.com"] currentReachabilityStatus];
    
    if (netStatus == NotReachable) {
        [self showNetworkNotReachableAlertView];
    } else {
        [self checkDeviceHasExistsHandler];
    }
}

- (void)checkDeviceHasExistsHandler {
    [self.progressHUD showProgressHUDWithMessage:/*@"Checking..."*/NSLocalizedString(@"kCheckDeviceWhetherBind", nil)];
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] checkDeviceHasExistsWithUID:[[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID] completion:^(BOOL isSuccess, id  _Nullable result) {
        NSLog(@"checkDeviceExistsWithUID is success: %d, result: %@", isSuccess, result);
        
        [weakself.progressHUD hideProgressHUD:YES];
        
        if (isSuccess) {
            NSNumber *exist = result;
            if (exist.integerValue == 1) {
                [weakself showDeviceExistAlertWithMessage:/*@"Device have been bind by other accounts."*/NSLocalizedString(@"kDeviceBindByOtherAccounts", nil)];
            } else {
                XJSetupWiFiVC *vc = [XJSetupWiFiVC setupWiFiVC];
                [weakself.navigationController pushViewController:vc animated:YES];
            }
        } else {
            [weakself showDeviceExistAlertWithMessage:/*@"Check the device has exists operation failed, please try again."*/NSLocalizedString(@"kCheckDeviceWhetherBindFailed", nil)];
        }
    }];
}

- (void)showNetworkNotReachableAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:/*@"⚠️ 当前网络不可用, 请检查手机网络设置。"*/NSLocalizedString(@"kNetworkNotReachable", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self viewWillAppear:YES];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupDeviceWiFi];
            [self viewWillAppear:YES];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)setupDeviceWiFi {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kEnterAPMode];
    
    NSString *urlString = @"App-Prefs:root=WIFI";
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:urlString]]) {
        if ([[UIDevice currentDevice].systemVersion doubleValue] >= 10.0) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
        }
    }
}

@end
