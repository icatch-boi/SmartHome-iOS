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
@property (weak, nonatomic) IBOutlet UILabel *upgradeDesLabel;

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
    NSString *btnTitle = NSLocalizedString(@"kCheckUpdate", nil);
    self.currentVersionLbl.text = [NSString stringWithFormat:NSLocalizedString(@"kLocalFWVersion", nil), [self getLocalVersion]];

    SHUpgradesInfo *info = self.camObj.cameraProperty.upgradesInfo;
    if (info != nil) {
        self.remoteVersionLbl.text = [NSString stringWithFormat:NSLocalizedString(@"kRemoteFWVersion", nil), info.versionid];
        
        if (info.needUpgrade == NO) {
//            btnTitle = @"当前已是最新版本";
//            self.upgradeButton.enabled = NO;
            self.upgradeDesLabel.text = NSLocalizedString(@"kAlreadyLatestVerdion", nil);
        } else {
            btnTitle = NSLocalizedString(@"kRightAwayUpdate", nil);

            [self.descriptionWebView loadHTMLString:info.html_description baseURL:nil];
        }
    }
    
//    self.currentVersionLbl.hidden = (info == nil);
    self.remoteVersionLbl.hidden = (info == nil);
    self.updateLabel.hidden = (info == nil || info.needUpgrade == NO);
    self.descriptionWebView.hidden = (info == nil || info.needUpgrade == NO);
    self.upgradeDesLabel.hidden = (info == nil || info.needUpgrade == YES);
    
    [self.upgradeButton setTitle:btnTitle forState:UIControlStateNormal];
    [self.upgradeButton setTitle:btnTitle forState:UIControlStateHighlighted];
}

- (NSString *)getLocalVersion {
    shared_ptr<ICatchCameraVersion> version = [self.camObj.controler.propCtrl retrieveCameraVersionWithCamera:self.camObj];

    return [NSString stringWithFormat:@"%s", version->getFirmwareVer().c_str()];
}

- (IBAction)upgradeClick:(id)sender {
    if (self.camObj.cameraProperty.upgradesInfo.needUpgrade == NO) {
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
        if (self.camObj.cameraProperty.clientCount > 1) {
            [self showCannotUpgradeAlert];
            
            SHLogWarn(SHLogTagAPP, @"Current cann't upgrade, client count: %zd", self.camObj.cameraProperty.clientCount);
            return;
        }
        
        SHDeviceUpgradeVC *vc = [SHDeviceUpgradeVC deviceUpgradeVCWithCameraObj:self.camObj];
        
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)showCannotUpgradeAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"其它用户正在连接，当前暂不能进行固件升级，谢谢!" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view ? self.view : self.navigationController.view];
    }
    
    return _progressHUD;
}

@end
