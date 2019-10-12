// SHSetupHomeViewController.m

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
 
 // Created by zj on 2019/10/9 5:08 PM.
    

#import "SHSetupHomeViewController.h"
#import "SHQRCodeScanningVC.h"
#import "SVProgressHUD.h"
#import "XJSetupWiFiVC.h"

@interface SHSetupHomeViewController ()

@property (weak, nonatomic) IBOutlet UILabel *scanDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *autoDescriptionLabel;

@end

@implementation SHSetupHomeViewController

+ (instancetype)setupHomeViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass(self.class)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [self resetParameter];
}

- (void)setupGUI {
    self.title = @"添加设备";
    self.scanDescriptionLabel.text = @"1、V35设备；\n2、设备不支持自动获取UUID方式；\n3、添加分享设备";
    self.autoDescriptionLabel.text = @"1、设备支持自动获取UUID方式";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(closeAction) isBack:NO];
}

- (void)closeAction {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)scanQRCodeWayClick:(id)sender {
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self scanQRCode];
    });
}

- (IBAction)autoWayClick:(id)sender {
    XJSetupWiFiVC *vc = [XJSetupWiFiVC setupWiFiVC];
    vc.autoWay = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)scanQRCode {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self presentQRCodeScanningVC];
                    
                    SGQRCodeLog(@"当前线程 - - %@", [NSThread currentThread]);
                    // 用户第一次同意了访问相机权限
                    SGQRCodeLog(@"用户第一次同意了访问相机权限");
                    
                } else {
                    
                    // 用户第一次拒绝了访问相机权限
                    SGQRCodeLog(@"用户第一次拒绝了访问相机权限");
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            [self presentQRCodeScanningVC];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kCameraAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            SHLogError(SHLogTagAPP, @"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kCameraNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)presentQRCodeScanningVC {
    dispatch_async(dispatch_get_main_queue(), ^{
        SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
        
        [self.navigationController pushViewController:vc animated:YES];
        
        [SVProgressHUD dismiss];
    });
}

- (void)resetParameter {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentAddCameraUID];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kReconfigureDevice];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
