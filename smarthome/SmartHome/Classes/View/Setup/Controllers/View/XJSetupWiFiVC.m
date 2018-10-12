// XJSetupWiFiVC.m

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
 
 // Created by zj on 2018/5/21 下午2:22.
    

#import "XJSetupWiFiVC.h"
#import "XJSetupTipsView.h"
#import "SHSetupWiFiCell.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "XJSetupDeviceSSIDVC.h"
#import "UnderLineTextField.h"

@interface XJSetupWiFiVC () <XJXJSetupTipsViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UnderLineTextField *ssidTextField;
@property (weak, nonatomic) IBOutlet UnderLineTextField *pwdTextField;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *changePasswordBtn;

@property (nonatomic, strong) XJSetupTipsView *tipsView;
@property (nonatomic, weak) UIView *coverView;

@end

@implementation XJSetupWiFiVC

+ (instancetype)setupWiFiVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"XJSetupWiFiVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
//    [self.navigationController.view addSubview:[self coverView]];
    
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.25 masksToBounds:NO];
    
    _ssidTextField.delegate = self;
    _pwdTextField.delegate = self;
    
    UIColor *color = [UIColor ic_colorWithHex:kButtonThemeColor];
    _ssidTextField.lineColor = color;
    _pwdTextField.lineColor = color;
    
    [self setupSSID];
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[UIImage imageNamed:@"nav-logo"] gradient:NO];
    [self addLineForChangePasswordBtn];
}

- (void)addLineForChangePasswordBtn {
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, _changePasswordBtn.frame.size.height - 5, _changePasswordBtn.frame.size.width, 1)];
    line.backgroundColor = _changePasswordBtn.currentTitleColor;
    
    [_changePasswordBtn addSubview:line];
}

- (void)setupSSID {
    NSArray *array = [self getWifiSSID];
    
    _ssidTextField.text = array.firstObject;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateSSIDStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateSSIDStatus {
    [self setupSSID];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)changeWiFiClick:(id)sender {
    [self setupDeviceWiFi];
}

- (IBAction)nextClick:(id)sender {
    [self verifyWiFiSetup];
}

- (IBAction)showPasswordClick:(id)sender {
    _pwdTextField.secureTextEntry = !_pwdTextField.secureTextEntry;
    
    NSString *imageName = _pwdTextField.secureTextEntry ? @"ic_visibility_off_18dp" : @"ic_visibility_18dp";
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [sender setImage:[UIImage imageNamed:imageName] forState:UIControlStateHighlighted];
}

- (UIView *)coverView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.screenWidth, UIScreen.screenHeight)];
    v.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
    
    self.tipsView.center = v.center;
    [v addSubview:self.tipsView];
    
    _coverView = v;
    
    return v;
}

- (void)verifyWiFiSetup {
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
    } else {
        [self performSegueWithIdentifier:@"go2SetupDeviceSSIDVCSegue" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2SetupDeviceSSIDVCSegue"]) {
        XJSetupDeviceSSIDVC *vc = segue.destinationViewController;

        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
    }
}

#pragma mark - TipsView
- (XJSetupTipsView *)tipsView {
    if (_tipsView == nil) {
        _tipsView = [XJSetupTipsView setupTipsView];
        _tipsView.frame = CGRectMake(0, 0, UIScreen.screenWidth * 0.85, UIScreen.screenHeight * 0.8);
        
        _tipsView.delegate = self;
    }
    
    return _tipsView;
}

- (void)closeTipsView:(XJSetupTipsView *)view {
    [UIView animateWithDuration:0.25 animations:^{
        _coverView.alpha = 0;
    } completion:^(BOOL finished) {
        [_tipsView removeFromSuperview];
        _tipsView = nil;
        [_coverView removeFromSuperview];
        _coverView = nil;
    }];
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

#pragma mark - UITextFiledDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
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