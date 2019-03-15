// SHDeviceUpgradeVC.m

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
 
 // Created by zj on 2019/3/14 2:11 PM.
    
static int totalCount = 10;

#import "SHDeviceUpgradeVC.h"
#import "SHProgressView.h"
#import "SHUpgradesInfo.h"
#import "SHSDKEventListener.hpp"

@interface SHDeviceUpgradeVC ()

@property (nonatomic, weak) SHCameraObject *camObj;
@property (weak, nonatomic) IBOutlet SHProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property (weak, nonatomic) IBOutlet UILabel *updateDesLabel;
@property (weak, nonatomic) IBOutlet UILabel *updateNoteLabel;
@property (weak, nonatomic) IBOutlet UIButton *finishButton;

@property (nonatomic, strong) SHObserver *downloadSizeObserver;
@property (nonatomic, strong) UIImageView *finishedImgView;

@property (nonatomic, strong) NSTimer *testTimer;
@property (nonatomic, assign) int count;

@end

@implementation SHDeviceUpgradeVC

+ (instancetype)deviceUpgradeVCWithCameraObj:(SHCameraObject *)camObj {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    
    SHDeviceUpgradeVC *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.camObj = camObj;
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    
    [self addDownloadSizeObserver];
//    [self testTimer];
    [self startUpgrade];
}

- (void)setupGUI {
    self.title = @"固件升级";
    self.navigationItem.hidesBackButton = YES;
    self.activityView.hidden = YES;
    
    self.updateDesLabel.text = @"更新中...";
    self.updateNoteLabel.text = @"更新中，请勿断电，等待升级完成之后再使用";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(upgradFailedHandle) name:kDeviceUpgradeFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(upgradSuccessHandle) name:kDeviceUpgradeSuccessNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)updateFinishClick:(id)sender {
    [self removeDownloadSizeObserver];
    [[SHCameraManager sharedCameraManger] destroyAllDeviceResoure];

    [self backToRootViewController];
}

- (void)backToRootViewController {
    UIViewController *presentingVc = self.presentingViewController;
    while (presentingVc.presentingViewController) {
        presentingVc = presentingVc.presentingViewController;
    }
    
    if (presentingVc) {
        [presentingVc dismissViewControllerAnimated:YES completion:nil];
        
        ZJSlidingDrawerViewController *slidingDrawerVC = (ZJSlidingDrawerViewController *)presentingVc;
        UINavigationController *nav = (UINavigationController *)slidingDrawerVC.mainVC;
        [nav popToRootViewControllerAnimated:YES];
    } else {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self testTimer];
}

- (NSTimer *)testTimer {
    if (_testTimer == nil) {
        _testTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(pregressHandle) userInfo:nil repeats:YES];
    }
    
    return _testTimer;
}

- (void)releaseTestTimer {
    if ([_testTimer isValid]) {
        [_testTimer invalidate];
        _testTimer = nil;
    }
}

- (void)pregressHandle {
    float progress = self.count++ * 1.0 / totalCount;
    if (self.count >= totalCount) {
        [self releaseTestTimer];

        [self downloadFinishHandle];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

- (void)downloadFinishHandle {
    [self removeDownloadSizeObserver];
    [[SHCameraManager sharedCameraManger] destroyAllDeviceResoure];

    self.progressView.hidden = YES;
    
    self.activityView.hidden = NO;
    CGAffineTransform transform = CGAffineTransformMakeScale(2.0, 2.0);
    self.activityView.transform = transform;
    [self.activityView startAnimating];
    
    self.updateDesLabel.text = @"安装更新中...";
    self.updateNoteLabel.text = @"安装过程需要重启设备，可能耗时较长，请耐心等待";
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self upgradFailedHandle];
    });
}

- (void)startUpgrade {
    NSString *version = self.camObj.cameraProperty.upgradesInfo.versionid;
    if (version == nil || version.length <= 0) {
        [self upgradFailedHandle];
        
        return;
    }
    
    int size = [self.camObj.cameraProperty.upgradesInfo.size intValue];
    if (size <= 0) {
        [self upgradFailedHandle];
        
        return;
    }
    
    NSArray *urls = self.camObj.cameraProperty.upgradesInfo.url;
    if (urls == nil || urls.count <= 0) {
        [self upgradFailedHandle];
        
        return;
    }
    
    std::list<std::string> *urlList = new list<std::string>;
    [urls enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        urlList->push_back(obj.UTF8String);
    }];
    
    int ret = self.camObj.sdk.control->downloadUpgradePackage(version.UTF8String, size, *urlList);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"downloadUpgradePackage failed, ret: %d", ret);
        [self upgradFailedHandle];
    }
}

- (void)upgradFailedHandle {
    [self.activityView stopAnimating];
    self.activityView.hidden = YES;
    
    self.finishButton.enabled = YES;
    
    self.finishedImgView.image = [UIImage imageNamed:@"nav-btn-cancel"];
    [self.view addSubview:self.finishedImgView];
    
    self.updateDesLabel.text = @"更新失败";
    self.updateDesLabel.textColor = [UIColor redColor];
    self.updateDesLabel.font = [UIFont systemFontOfSize:20.0];
    
    self.updateNoteLabel.hidden = YES;
}

- (void)upgradSuccessHandle {
    [self.activityView stopAnimating];
    self.activityView.hidden = YES;
    
    self.finishButton.enabled = YES;
    
    self.finishedImgView.image = [UIImage imageNamed:@"Checkmark"];
    [self.view addSubview:self.finishedImgView];
    
    self.updateDesLabel.text = @"更新成功";
    self.updateDesLabel.textColor = [UIColor blueColor];
    self.updateDesLabel.font = [UIFont systemFontOfSize:20.0];

    self.updateNoteLabel.hidden = YES;
}

#pragma mark - Download Observer
- (void)addDownloadSizeObserver {
    SHSDKEventListener *downloadSizeListener = new SHSDKEventListener(self, @selector(downloadSizeCallback:));
    self.downloadSizeObserver = [SHObserver cameraObserverWithListener:downloadSizeListener eventType:ICATCH_EVENT_UPGRADE_PACKAGE_DOWNLOADED_SIZE isCustomized:NO isGlobal:NO];
    [self.camObj.sdk addObserver:self.downloadSizeObserver];
}

- (void)removeDownloadSizeObserver {
    if (self.downloadSizeObserver != nil) {
        [self.camObj.sdk removeObserver:self.downloadSizeObserver];
        
        if (self.downloadSizeObserver.listener) {
            delete self.downloadSizeObserver.listener;
            self.downloadSizeObserver.listener = nullptr;
        }
        
        self.downloadSizeObserver = nil;
    }
}

- (void)downloadSizeCallback:(SHICatchEvent *)event {
    int recv = event.intValue1;
    int total = event.intValue2;
    
    float progress = recv * 1.0 / total;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
        
        if (progress >= 1.0) {
            [self downloadFinishHandle];
        }
    });
}

- (UIImageView *)finishedImgView {
    if (_finishedImgView == nil) {
        _finishedImgView = [[UIImageView alloc] initWithFrame:self.progressView.frame];
        _finishedImgView.backgroundColor = [UIColor lightGrayColor];
    }
    
    return _finishedImgView;
}

@end
