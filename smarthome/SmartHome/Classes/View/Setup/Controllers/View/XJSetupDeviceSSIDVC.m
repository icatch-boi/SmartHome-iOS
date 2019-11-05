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
#import <CoreLocation/CoreLocation.h>

static const CGFloat kTipsViewDefaultHeight = 140;
static const CGFloat kChooseWiFiIconDefauleHeight = 160;

@interface XJSetupDeviceSSIDVC ()<CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipsViewHeightCons;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *chooseWifiDesLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exitButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chooseWiFiIconHeightCons;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation XJSetupDeviceSSIDVC
- (void)dealloc {
    SHLogInfo(SHLogTagAPP, @"%@ - dealloc", self.class);
}

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
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[[UIImage imageNamed:@"nav-logo"] imageWithTintColor:[UIColor whiteColor]] gradient:NO];
    
    _titleLabel.textColor = [UIColor ic_colorWithHex:kTextThemeColor];
    _chooseWifiDesLabel.textColor = [UIColor ic_colorWithHex:kTextThemeColor];
    _chooseWiFiIconHeightCons.constant = kChooseWiFiIconDefauleHeight * kScreenHeightScale;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
        
    if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
        [self requestLocationPermission];
    } else {
        [self checkConnectState];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateConnectState) name:UIApplicationDidBecomeActiveNotification object:nil];
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

- (void)updateConnectState {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
        [self requestLocationPermission];
    } else {
        [self checkConnectState];
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
    if ([currentSSID hasPrefix:kCameraSSIDPrefix] || [currentSSID hasPrefix:@"X-Sense-"]) {
        [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateNormal];
        [_nextButton setTitle:NSLocalizedString(@"kNext", nil) forState:UIControlStateHighlighted];
        _nextButton.tag = 1;
        [self nextClick:nil];
    } else {
        [_nextButton setTitle:NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateNormal];
        [_nextButton setTitle:NSLocalizedString(@"kGotoWiFiSetting", nil) forState:UIControlStateHighlighted];
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
    
    [SHTool appToSystemSettings];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - CLLocationManager
- (void)requestLocationPermission {
    if ([CLLocationManager locationServicesEnabled]){
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    SHLogInfo(SHLogTagAPP, @"status: %d", status);
    
    switch (status) {
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self showLocationAuthorizationAlertView];
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self checkConnectState];
            break;
            
        default:
            break;
    }
}

- (void)showLocationAuthorizationAlertView {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kLocationAuthorizationDeniedNotice", nil) preferredStyle:UIAlertControllerStyleAlert];
    WEAK_SELF(self);
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself setupDeviceWiFi];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    SHLogError(SHLogTagAPP, @"Location happened error: %@", error.description);
}

@end
