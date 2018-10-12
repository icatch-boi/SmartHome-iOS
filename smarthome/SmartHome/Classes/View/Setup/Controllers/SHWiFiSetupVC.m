//
//  SHSetupWiFiVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/13.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHWiFiSetupVC.h"
#import "SHSetupCameraPWDVC.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "SHTurnonCameraVC.h"

static CGFloat const kTextFieldFontSize_CN = 14;
static CGFloat const kTextFieldFontSize_EN = 12;

@interface SHWiFiSetupVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UITextField *ssidTextField;
@property (weak, nonatomic) IBOutlet UITextField *pwdTextField;
@property (weak, nonatomic) IBOutlet UILabel *connectWifiLab;
@property (weak, nonatomic) IBOutlet UILabel *ssidLabel;
@property (weak, nonatomic) IBOutlet UILabel *pwdLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UILabel *showPWDLab;

@end

@implementation SHWiFiSetupVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
    [self setupSSID];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSSIDStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupGUI {
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_nextButton setBorderWidth:1.0 borderColor:_nextButton.titleLabel.textColor];
    
    _ssidTextField.delegate = self;
    _pwdTextField.delegate = self;
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _connectWifiLab.text = NSLocalizedString(@"kSetupConnectWifi", nil);
    _ssidLabel.text = NSLocalizedString(@"kWifiSSID", nil);
    _ssidTextField.placeholder = NSLocalizedString(@"kWifiSSIDInfo", nil);
    _pwdLabel.text = NSLocalizedString(@"kWifiPassword", nil);
    _pwdTextField.placeholder = NSLocalizedString(@"kWifiPasswordInfo", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_nextButton title:NSLocalizedString(@"kNext", nil)];
    
    [self updateTextFieldPropertyByAppLanguage];
    _showPWDLab.text = NSLocalizedString(@"kShowPassword", nil);
}

- (void)updateTextFieldPropertyByAppLanguage {
    // 获取当前设备语言
    NSArray *appLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *languageName = [appLanguages objectAtIndex:0];
    
    if ([languageName isEqualToString:@"zh-Hans-CN"] || [languageName isEqualToString:@"zh-Hant-CN"]) {
        _pwdTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize_CN];
    } else {
        _pwdTextField.font = [UIFont systemFontOfSize:kTextFieldFontSize_EN];
    }
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)updateButtonBorderColor:(UIButton *)btn {
    btn.layer.borderColor = btn.titleLabel.textColor.CGColor;
}

- (void)updateSSIDStatus {
    [self setupSSID];
}

- (void)setupSSID {
//    if (!self.isAPMode) {
        NSArray *array = [self getWifiSSID];
        
        _ssidTextField.text = array.firstObject;
//        _ssidTextField.enabled = NO;
//    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)showPasswordClick:(UISwitch *)sender {
    _pwdTextField.secureTextEntry = !sender.isOn;
}

- (IBAction)nextClick:(UIButton *)sender {
    [_ssidTextField resignFirstResponder];
    [_pwdTextField resignFirstResponder];
    
    NSRange ssidRange = [_ssidTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
    NSRange pwdRange = [_pwdTextField.text rangeOfString:@"[A-Za-z0-9_(?![，。？：；’‘！”“、]]{8,63}" options:NSRegularExpressionSearch];
    
    if (ssidRange.location == NSNotFound || pwdRange.location == NSNotFound) {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kInvalidSSIDOrPassword", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertC animated:YES completion:nil];
        });
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
//                                                            message:@"Invalid information."
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil, nil];
//            [alert show];
//        });
        
    } else {
        if (sender.tag == 0) {
            [self performSegueWithIdentifier:@"go2SetupCameraPWDSegue" sender:nil];
        } else if (sender.tag == 1) {
            [self performSegueWithIdentifier:@"go2TurnonCameraVCSegue" sender:nil];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2SetupCameraPWDSegue"]) {
        SHSetupCameraPWDVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
    } else if ([segue.identifier isEqualToString:@"go2TurnonCameraVCSegue"]) {
        SHTurnonCameraVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
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
        
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }]];
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakself setupDeviceWiFi];
        }]];
        [self presentViewController:alertC animated:YES completion:nil];
        
//        _nextButton.enabled = NO;
//        [self updateButtonBorderColor:_nextButton];
        
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

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    NSRange cameraUidRange = [_ssidTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
//    NSRange cameraNameRange = [_pwdTextField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
//
//    if (cameraUidRange.location == NSNotFound || cameraNameRange.location == NSNotFound) {
//        _nextButton.enabled = NO;
//    } else {
//        _nextButton.enabled = YES;
//    }
//    [self updateButtonBorderColor:_nextButton];
    [textField resignFirstResponder];
    
    return YES;
}

@end
