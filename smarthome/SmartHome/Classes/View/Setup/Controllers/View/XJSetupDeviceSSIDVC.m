// XJSetupDeviceSSIDVC.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/5/21 下午4:51.
    

#import "XJSetupDeviceSSIDVC.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "XJSetupDeviceInfoVC.h"

static const CGFloat kTipsViewDefaultHeight = 140;

@interface XJSetupDeviceSSIDVC ()

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewHeightCons;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *chooseWifiDesLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exitButtonItem;

@end

@implementation XJSetupDeviceSSIDVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupLocalizedString];
    [self setupGUI];
}

- (void)setupLocalizedString {
    _titleLabel.text = NSLocalizedString(@"kSelectDeviceWiFi", nil);
    _chooseWifiDesLabel.text = [NSString stringWithFormat:NSLocalizedString(@"kSelectDeviceWiFiDes", nil), kCameraSSIDPrefix];
    [_nextButton setTitle:NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateNormal];
    [_nextButton setTitle:NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateHighlighted];
    [_exitButtonItem setTitle:NSLocalizedString(@"kExit", nil)];
}

- (void)setupGUI {
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.25 masksToBounds:NO];
    _tipsViewHeightCons.constant = kTipsViewDefaultHeight * kScreenHeightScale;
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[UIImage imageNamed:@"nav-logo"] gradient:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self checkConnectState];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkConnectState) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)nextClick:(id)sender {
    if (_nextButton.tag) {
        SHLogTRACE();
        [self performSegueWithIdentifier:@"go2SetupDeviceInfoVCSegue" sender:nil];
    } else {
        [self setupDeviceWiFi];
    }
}

- (void)checkConnectState {
    NSArray *array = [self getWifiSSID];
    SHLogInfo(SHLogTagAPP, @"return array: %@", array);
    if (array == nil) {
        SHLogError(SHLogTagAPP, @"WiFi SSID array is nil.");
        return;
    }
    
    NSString *currentSSID = array.firstObject;
    SHLogInfo(SHLogTagAPP, @"currentSSID: %@", currentSSID);
    if ([currentSSID hasPrefix:kCameraSSIDPrefix] || [currentSSID hasPrefix:@"SH-IPC_"]) {
        [_nextButton setTitle:/*@"Next"*/NSLocalizedString(@"kNext", nil) forState:UIControlStateNormal];
        [_nextButton setTitle:/*@"Next"*/NSLocalizedString(@"kNext", nil) forState:UIControlStateHighlighted];
        _nextButton.tag = 1;
        [self nextClick:nil];
    } else {
        [_nextButton setTitle:/*@"Go to wifi setting"*/NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateNormal];
        [_nextButton setTitle:/*@"Go to wifi setting"*/NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateHighlighted];
        _nextButton.tag = 0;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2SetupDeviceInfoVCSegue"]) {
        XJSetupDeviceInfoVC *vc = segue.destinationViewController;
        
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
