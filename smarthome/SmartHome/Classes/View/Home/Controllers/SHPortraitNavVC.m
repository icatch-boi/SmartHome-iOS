//
//  SHPortraitNavVC.m
//  SmartHome
//
//  Created by ZJ on 2017/4/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPortraitNavVC.h"

@interface SHPortraitNavVC ()

@property (nonatomic) BOOL disconnectHandling;
@property (nonatomic) MBProgressHUD *progressHUD;
//@property (nonatomic) BOOL poweroffHandling;

@end

@implementation SHPortraitNavVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGUI {
    [SHTool configureAppThemeWithController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cameraDisconnectHandle:(NSNotification *)nc {
    if (_disconnectHandling) {
        return;
    }
    
    _disconnectHandling = YES;
    SHCameraObject *shCamObj = nc.object;
    
    if (!shCamObj.isConnect) {
        return;
    }
    
    if (shCamObj.controler.actCtrl.isRecord) {
        [shCamObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
    }
    
    if (shCamObj.streamOper.PVRun) {
        [shCamObj.streamOper stopMediaStreamWithComplete:^{
            [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }];
    } else {
        [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
    }
    
    [self showDisconnectAlert:shCamObj];
}

- (void)cameraPowerOffHandle:(NSNotification *)nc {
//    if (_poweroffHandling) {
//        return;
//    }
//
//    _poweroffHandling = YES;
    _disconnectHandling = YES;
    SHCameraObject *shCamObj = nc.object;
    [shCamObj.sdk disableTutk];
    
    if (shCamObj.controler.actCtrl.isRecord) {
        [shCamObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
    }
    
    if (shCamObj.streamOper.PVRun) {
        [shCamObj.streamOper stopMediaStreamWithComplete:^{
            [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }];
    } else {
        [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
    }
    
    NSDictionary *userInfo = nc.userInfo;
    int value = [userInfo[kPowerOffEventValue] intValue];
    NSString *tipsInfo = NSLocalizedString(@"kCameraPowerOff", nil);
    if (value == 1) {
        tipsInfo = NSLocalizedString(@"kCameraPowerOffByRemoveSDCard", nil);
    }
    
    WEAK_SELF(self);
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:[NSString stringWithFormat:@"[%@] %@", shCamObj.camera.cameraName, tipsInfo] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            weakself.disconnectHandling = NO;
            weakself.disconnectHandling = NO;

            UIViewController *vc = self.topViewController;
            NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
            if ([className isEqualToString:@"SHCameraListTVC"]) {
                // FIXME: need modify
#if 0
                SHCameraListTVC *listVC = (SHCameraListTVC *)vc;
                [listVC.tableView reloadData];
#endif
            } else {
//                [weakself dismissViewControllerAnimated:YES completion:nil];
                [SHTool backToRootViewControllerWithCompletion:^{
                    [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
                }];
            }
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Disconnect & Reconnect
- (void)showDisconnectAlert:(SHCameraObject *)shCamObj {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"kDisconnect", nil)] message:NSLocalizedString(@"kDisconnectTipsInfo", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Exit", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _disconnectHandling = NO;
            
            UIViewController *vc = self.topViewController;
            NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
            if ([className isEqualToString:@"SHCameraListTVC"]) {
                // FIXME: need modify
#if 0
                SHCameraListTVC *listVC = (SHCameraListTVC *)vc;
                [listVC.tableView reloadData];
#endif
            } else {
//                [self dismissViewControllerAnimated:YES completion:nil];
                [SHTool backToRootViewControllerWithCompletion:^{
                    [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
                }];
            }
        });
    }]];
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"STREAM_RECONNECT", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf reconnect:shCamObj];
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertVc animated:YES completion:nil];
    });
}

- (void)reconnect:(SHCameraObject *)shCamObj {
    [self.progressHUD showProgressHUDWithMessage:[NSString stringWithFormat:@"%@ %@...", shCamObj.camera.cameraName, NSLocalizedString(@"kReconnecting", nil)]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        int retValue = [shCamObj connectCamera];
        if (retValue == ICH_SUCCEED) {
            [shCamObj initCamera];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                
                UIViewController *vc = self.topViewController;
                NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
                if ([className isEqualToString:@"SHCameraListTVC"]) {
                    // FIXME: need modify
#if 0
                    SHCameraListTVC *listVC = (SHCameraListTVC *)vc;
                    [listVC.tableView reloadData];
#endif
                } else {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kCameraNetworkConnectedNotification object:nil];
                }
                
                _disconnectHandling = NO;
            });
        } else {
            NSString *name = shCamObj.camera.cameraName;
            NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
            NSString *errorInfo = @"";
            errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
            
            [self showConnectErrorAlert:errorInfo cameraObj:shCamObj];
        }
    });
}

- (void)showConnectErrorAlert:(NSString *)errorInfo cameraObj:(SHCameraObject *)shCamObj {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"ConnectError", nil)] message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _disconnectHandling = NO;
            
            UIViewController *vc = self.topViewController;
            NSString *className = [NSString stringWithFormat:@"%@", [vc class]];
            if ([className isEqualToString:@"SHCameraListTVC"]) {
                // FIXME: need modify
#if 0
                SHCameraListTVC *listVC = (SHCameraListTVC *)vc;
                [listVC.tableView reloadData];
#endif
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
        [self presentViewController:alertVc animated:YES completion:nil];
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}

@end
