//
//  SHSetupHomeVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/12.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSetupHomeVC.h"
#import "SHQRCodeScanningVC.h"
#import "SHNetworkDetectionVC.h"
#import "SHWiFiSetupVC.h"

@interface SHSetupHomeVC ()

@property (weak, nonatomic) IBOutlet UIButton *smartLinkButton;
@property (weak, nonatomic) IBOutlet UIButton *scanQRButton;
@property (weak, nonatomic) IBOutlet UIButton *apmodeButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

@end

@implementation SHSetupHomeVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // FIXME: ---
//    _smartLinkButton.enabled = NO;
    
    [self setupGUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGUI {
    [_smartLinkButton setCornerWithRadius:_smartLinkButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_smartLinkButton setBorderWidth:1.0 borderColor:_smartLinkButton.titleLabel.textColor];
    
    [_scanQRButton setCornerWithRadius:_scanQRButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_scanQRButton setBorderWidth:1.0 borderColor:_smartLinkButton.titleLabel.textColor];
    
    [_apmodeButton setCornerWithRadius:_apmodeButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_apmodeButton setBorderWidth:1.0 borderColor:_apmodeButton.titleLabel.textColor];
    
    _titleLabel.text = NSLocalizedString(@"kCameraSetup", nil);
    [self setButtonTitle:_apmodeButton title:NSLocalizedString(@"kAPModeWaySetupCamera", nil)];
    [self setButtonTitle:_smartLinkButton title:NSLocalizedString(@"kStandardWaySetupCamera", nil)];
    [self setButtonTitle:_scanQRButton title:NSLocalizedString(@"kQRCodeWaySetupCamera", nil)];
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (IBAction)scanQRCodeClick:(UIButton *)sender {
    [self scanQRCode];
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (void)scanQRCode {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
                        vc.managedObjectContext = _managedObjectContext;
                        [self.navigationController pushViewController:vc animated:YES];
                    });
                    
                    SGQRCodeLog(@"当前线程 - - %@", [NSThread currentThread]);
                    // 用户第一次同意了访问相机权限
                    SGQRCodeLog(@"用户第一次同意了访问相机权限");
                    
                } else {
                    
                    // 用户第一次拒绝了访问相机权限
                    SGQRCodeLog(@"用户第一次拒绝了访问相机权限");
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
            vc.managedObjectContext = _managedObjectContext;
            [self.navigationController pushViewController:vc animated:YES];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kCameraAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kCameraNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2NetworkDetectionSegue"]) {
        SHNetworkDetectionVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
    } else if ([segue.identifier isEqualToString:@"go2WiFiAPSetupSegue"]) {
        SHWiFiSetupVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
    }
}

- (IBAction)standardSetupAction:(id)sender {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
                        vc.managedObjectContext = _managedObjectContext;
                        vc.isStandardMode = YES;
                        [self.navigationController pushViewController:vc animated:YES];
                    });
                    
                    SGQRCodeLog(@"当前线程 - - %@", [NSThread currentThread]);
                    // 用户第一次同意了访问相机权限
                    SGQRCodeLog(@"用户第一次同意了访问相机权限");
                    
                } else {
                    
                    // 用户第一次拒绝了访问相机权限
                    SGQRCodeLog(@"用户第一次拒绝了访问相机权限");
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
            vc.managedObjectContext = _managedObjectContext;
            vc.isStandardMode = YES;
            [self.navigationController pushViewController:vc animated:YES];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kCameraAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kCameraNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

@end
