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
    
    [self devicePropertyChangeHandle];
    self.hasBegun ? void() : [self startUpgrade];
}

- (void)setupGUI {
    self.title = NSLocalizedString(@"kFWUpgrade", nil);
    self.navigationItem.hidesBackButton = YES;
    self.activityView.hidden = YES;
    
    self.updateDesLabel.text = NSLocalizedString(@"kUpdating", nil);
    self.updateNoteLabel.text = NSLocalizedString(@"kFWUpdateDescription", nil);
    self.updateNoteLabel.textColor = [UIColor orangeColor];
    self.activityView.color = [UIColor orangeColor];
    
    [self.finishButton setTitle:@"完成" forState:UIControlStateNormal];
    [self.finishButton setTitle:@"完成" forState:UIControlStateHighlighted];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addUpgradeObserver];
}

- (void)addUpgradeObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(upgradeFailedHandle) name:kDeviceUpgradeFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(upgradeSuccessHandle) name:kDeviceUpgradeSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(downloadFinishHandle) name:kDownloadUpgradePackageSuccessNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)updateFinishClick:(id)sender {
//    [[SHCameraManager sharedCameraManger] destroyAllDeviceResoure];
//
//    [self backToRootViewController];
    [SHTool backToRootViewController];
    [self.camObj disConnectWithSuccessBlock:nil failedBlock:nil];
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

- (void)downloadFinishHandle {
//    [[SHCameraManager sharedCameraManger] destroyAllDeviceResoure];
    [self.camObj disConnectWithSuccessBlock:nil failedBlock:nil];

    self.progressView.hidden = YES;
    
    self.activityView.hidden = NO;
    CGAffineTransform transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.activityView.transform = transform;
    [self.activityView startAnimating];
    
    self.updateDesLabel.text = NSLocalizedString(@"kInstallUpdating", nil);
    self.updateNoteLabel.text = NSLocalizedString(@"kFWInstallDescription", nil);
}

- (void)startUpgrade {
    NSString *version = self.camObj.cameraProperty.upgradesInfo.versionid;
    if (version == nil || version.length <= 0) {
        [self upgradeFailedHandle];
        
        return;
    }
    
    int size = [self.camObj.cameraProperty.upgradesInfo.size intValue];
    if (size <= 0) {
        [self upgradeFailedHandle];
        
        return;
    }
    
    NSArray *urls = self.camObj.cameraProperty.upgradesInfo.url;
    if (urls == nil || urls.count <= 0) {
        [self upgradeFailedHandle];
        
        return;
    }
    
    std::list<std::string> *urlList = new list<std::string>;
    [urls enumerateObjectsUsingBlock:^(NSString * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        urlList->push_back(obj.UTF8String);
    }];
    
    int ret = self.camObj.sdk.control->upgradeFW(version.UTF8String, size, *urlList);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"downloadUpgradePackage failed, ret: %d", ret);
        ret != ICH_ERR_IS_DOWNLOADING ? [self upgradeFailedHandle] : void();
        
        [self upgradeErrorHandle:ret];
    }
}

- (void)upgradeErrorHandle:(int)errorno {
    switch (errorno) {
        case ICH_SD_CARD_NOT_EXIST:
            [self showUpgradeFailedAlertWithMessage:NSLocalizedString(@"NoCard", nil)];
            break;
            
        case ICH_SD_CARD_MEMORY_FULL:
            [self showUpgradeFailedAlertWithMessage:NSLocalizedString(@"CARD_FULL", nil)];
            break;
            
        case ICH_PROP_NOT_SUPPORTED:
            [self showUpgradeFailedAlertWithMessage:NSLocalizedString(@"kNetworkRequestError_10061", nil)];
            break;
            
        case ICH_ERR_DEVICE_LOCAL_PLAYBACK:
            [self showUpgradeFailedAlertWithMessage:NSLocalizedString(@"kLocalPlaybackDescription", nil)];
            break;
            
        default:
            break;
    }
}

- (void)showUpgradeFailedAlertWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)upgradeFailedHandle {
    [self upgradeFinishWithSuccess:NO];
}

- (void)upgradeSuccessHandle {
    [self upgradeFinishWithSuccess:YES];
}

- (void)upgradeFinishWithSuccess:(BOOL)success {
    [self.activityView stopAnimating];
    self.activityView.hidden = YES;
    
    self.finishButton.enabled = YES;
    
    UIImage *image = [UIImage imageNamed:@"upgrade-success"];
    NSString *updateDes = NSLocalizedString(@"kUpdateSuccess", nil);
    UIColor *textColor = [UIColor greenColor];
    if (success == NO) {
        image = [UIImage imageNamed:@"upgrade-fail"];
        updateDes = NSLocalizedString(@"kUpdateFailed", nil);
        textColor = [UIColor redColor];
    }

    self.finishedImgView.image = image;
    [self.view addSubview:self.finishedImgView];
    
    self.updateDesLabel.text = updateDes;
    self.updateDesLabel.textColor = textColor;
    self.updateDesLabel.font = [UIFont systemFontOfSize:20.0];
    
    self.updateNoteLabel.hidden = YES;
    self.progressView.hidden = YES;
}

#pragma mark - Download Observer
- (void)devicePropertyChangeHandle {
    WEAK_SELF(self);
    
    [self.camObj setCameraPropertyValueChangeBlock:^ (SHICatchEvent *evt){
        switch (evt.eventID) {
            case ICATCH_EVENT_UPGRADE_PACKAGE_DOWNLOADED_SIZE:
                [weakself packageDownloadSizeCallback:evt];
                break;
                
            default:
                break;
        }
    }];
}

- (void)packageDownloadSizeCallback:(SHICatchEvent *)event {
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
        _finishedImgView = [[UIImageView alloc] initWithFrame:[self finishedFrame]];
    }
    
    return _finishedImgView;
}

- (CGRect)finishedFrame {
    CGFloat width = 120;
    CGFloat height = width;
    CGFloat x = (CGRectGetWidth(self.view.frame) - width ) * 0.5;
    CGFloat y = CGRectGetMinY(self.updateDesLabel.frame) - 20 - height;
    return CGRectMake(x, y, width, height);
}

@end
