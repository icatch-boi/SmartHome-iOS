//
//  SHSetupNav.m
//  SmartHome
//
//  Created by ZJ on 2017/12/13.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSetupNavVC.h"

@interface SHSetupNavVC ()

@end

@implementation SHSetupNavVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCameraExitHandle:) name:kAddCameraExitNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addCameraExitHandle:(NSNotification *)notification {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kExitCameraSetupTipsInfo", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kNo", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kYes", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)cameraDisconnectHandle:(NSNotification *)nc {
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
}

- (void)cameraPowerOffHandle:(NSNotification *)nc {
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
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:[NSString stringWithFormat:@"[%@] %@", shCamObj.camera.cameraName, tipsInfo] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
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
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
