//
//  SHAPModeViewController.m
//  SmartHome
//
//  Created by ZJ on 2017/12/15.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHAPModeViewController.h"
#import "SHSetupCameraPWDVC.h"
#import "SHCameraInfoViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>

@interface SHAPModeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UIButton *connectWiFiBtn;
@property (weak, nonatomic) IBOutlet UILabel *findLabel;
@property (weak, nonatomic) IBOutlet UILabel *findInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *apmodeInfoLab;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

@end

@implementation SHAPModeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kEnterAPMode];
}

- (void)setupGUI {
    [_connectButton setCornerWithRadius:_connectButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_connectButton setBorderWidth:1.0 borderColor:_connectButton.titleLabel.textColor];
    [_connectWiFiBtn setCornerWithRadius:_connectWiFiBtn.bounds.size.height * 0.25 masksToBounds:YES];
    [_connectWiFiBtn setBorderWidth:1.0 borderColor:_connectWiFiBtn.titleLabel.textColor];
    
    _findLabel.hidden = _directEnterAPMode;
    _findInfoLabel.font = _directEnterAPMode ? [UIFont systemFontOfSize:18.0] : [UIFont systemFontOfSize:16.0];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _findLabel.text = NSLocalizedString(@"kNotFindCamera", nil);
    _findInfoLabel.text = NSLocalizedString(@"kEnterAPMode", nil);
    _apmodeInfoLab.text = [NSString stringWithFormat:NSLocalizedString(@"kAPModeUseFlowInfo", nil), NSLocalizedString(@"kConnectCameraWifi", nil), kCameraSSIDPrefix];
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_connectWiFiBtn title:NSLocalizedString(@"kConnectCameraWifi", nil)];
    [self setButtonTitle:_connectButton title:NSLocalizedString(@"kConnectCameraWifiReady", nil)];
    
    _connectButton.titleLabel.numberOfLines = 0;
    _connectButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    _connectWiFiBtn.titleLabel.numberOfLines = 0;
    _connectWiFiBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)connectCameraClick:(id)sender {
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

- (IBAction)nextClick:(id)sender {
    NSArray *array = [self getWifiSSID];
    SHLogInfo(SHLogTagAPP, @"return array: %@", array);
    if (array == nil) {
        SHLogError(SHLogTagAPP, @"WiFi SSID array is nil.");
        return;
    }
    
    NSString *currentSSID = array.firstObject;
    SHLogInfo(SHLogTagAPP, @"currentSSID: %@", currentSSID);
    if ([currentSSID hasPrefix:kCameraSSIDPrefix]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_directEnterAPMode) {
                SHLogTRACE();
                [self performSegueWithIdentifier:@"go2APPSetupCameraPWDSegue" sender:nil];
            } else {
                SHLogTRACE();
                [self performSegueWithIdentifier:@"go2CameraInfoDirectSegue" sender:nil];
            }
        });
    } else {
        SHLogTRACE();
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[NSString stringWithFormat:@"%@ (%@xxx...)", NSLocalizedString(@"kSuccessfulConnectCameraWiFi", @""), kCameraSSIDPrefix] preferredStyle:UIAlertControllerStyleAlert];
        WEAK_SELF(self);
        
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleDestructive handler:nil]];
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToCheck", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakself setupDeviceWiFi];
        }]];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"go2APPSetupCameraPWDSegue"]) {
        SHSetupCameraPWDVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        // FIXME: -- 模拟找到相机
//        vc.cameraUid = @"1JWFSXRHX9AVM59K111A";
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
    } else if ([segue.identifier isEqualToString:@"go2CameraInfoDirectSegue"]) {
        SHCameraInfoViewController *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
        vc.devicePWD = _devicePWD;
    }
}

- (NSArray *)getWifiSSID {
    // Does not work on the simulator.
    NSString *mssid = nil;
    NSString *mmac = nil;
    NSArray *ifs = (  id)CFBridgingRelease(CNCopySupportedInterfaces());
    NSLog(@"ifs:%@",ifs);
    for (NSString *ifnam in ifs) {
        NSDictionary *info = (id)CFBridgingRelease(CNCopyCurrentNetworkInfo((CFStringRef)ifnam));
        NSLog(@"dici：%@",[info  allKeys]);
        if (info[@"SSID"]) {
            mssid = info[@"SSID"];
            
        }
        
        if (info[@"BSSID"]) {
            mmac = info[@"BSSID"];
            mmac = [mmac stringByReplacingOccurrencesOfString:@":" withString:@""];
        }
        NSLog(@"BSSID:%@",info[@"BSSID"]);
        NSLog(@"mac:%@",mmac);
    }
    NSLog(@"ssid:%@",mssid);
    
    if (!mssid) {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kConnectSuccessfulToWiFi", @"") preferredStyle:UIAlertControllerStyleAlert];
        WEAK_SELF(self);
        
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }]];
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakself setupDeviceWiFi];
        }]];
        [self presentViewController:alertC animated:YES completion:nil];
                
        return nil;
    } else return @[mssid,mmac];
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
