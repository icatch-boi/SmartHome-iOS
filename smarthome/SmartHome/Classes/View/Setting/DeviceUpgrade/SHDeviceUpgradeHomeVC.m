// SHUpgradesViewController.m

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
 
 // Created by zj on 2019/3/13 4:56 PM.
    

#import "SHDeviceUpgradeHomeVC.h"
#import "SHUpgradesInfo.h"
#import "SHDeviceUpgradeVC.h"

@interface SHDeviceUpgradeHomeVC ()

@property (weak, nonatomic) IBOutlet UILabel *currentVersionLbl;
@property (weak, nonatomic) IBOutlet UILabel *remoteVersionLbl;

@property (weak, nonatomic) IBOutlet UILabel *updateLabel;
@property (weak, nonatomic) IBOutlet UIWebView *descriptionWebView;

@property (weak, nonatomic) IBOutlet UIButton *upgradeButton;

@property (nonatomic, weak) SHCameraObject *camObj;
@property (nonatomic, weak) MBProgressHUD *progressHUD;

@end

@implementation SHDeviceUpgradeHomeVC

+ (instancetype)deviceUpgradeHomeVCWithCameraObj:(SHCameraObject *)camObj {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    
    SHDeviceUpgradeHomeVC *vc = [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
    vc.camObj = camObj;
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
    NSString *btnTitle = @"检测更新";
    
    SHUpgradesInfo *info = self.camObj.cameraProperty.upgradesInfo;
    if (info != nil) {
        btnTitle = @"立即更新";
        
        self.currentVersionLbl.text = [NSString stringWithFormat:@"当前版本 %@", info.localVersion];
        self.remoteVersionLbl.text = [NSString stringWithFormat:@"最新版本 %@", info.versionid];
        
        if (info.needUpgrade == NO) {
            btnTitle = @"当前已是最新版本";
            self.upgradeButton.enabled = NO;
        } else {
            [self.descriptionWebView loadHTMLString:info.html_description baseURL:nil];
        }
    }
    
    self.currentVersionLbl.hidden = (info == nil);
    self.remoteVersionLbl.hidden = (info == nil);
    self.updateLabel.hidden = (info == nil || info.needUpgrade == NO);
    self.descriptionWebView.hidden = (info == nil || info.needUpgrade == NO);
    
    [self.upgradeButton setTitle:btnTitle forState:UIControlStateNormal];
    [self.upgradeButton setTitle:btnTitle forState:UIControlStateHighlighted];
}

- (IBAction)upgradeClick:(id)sender {
    if (self.camObj.cameraProperty.upgradesInfo == nil) {
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kTesting3", nil)];
        
        WEAK_SELF(self);
        [SHUpgradesInfo checkUpgradesWithCameraObj:self.camObj completion:^(BOOL hint, SHUpgradesInfo * _Nullable info) {
            STRONG_SELF(self);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self setupGUI];
            });
        }];
    } else {
        SHDeviceUpgradeVC *vc = [SHDeviceUpgradeVC deviceUpgradeVCWithCameraObj:self.camObj];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)alreadyLatestVersionHandle {
    NSString *title = @"已是最新版本";
    [self.upgradeButton setTitle:title forState:UIControlStateNormal];
    [self.upgradeButton setTitle:title forState:UIControlStateHighlighted];
    
    self.upgradeButton.enabled = NO;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view ? self.view : self.navigationController.view];
    }
    
    return _progressHUD;
}

@end
