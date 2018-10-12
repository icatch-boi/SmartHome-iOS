// SHSetupWiFiViewController.m

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
 
 // Created by zj on 2018/4/20 上午9:52.
    

#import "SHSetupWiFiViewController.h"
#import "SHSetupWiFiCell.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "SHTurnonCameraVC.h"

static CGFloat const kTextFieldFontSize_CN = 14;
static CGFloat const kTextFieldFontSize_EN = 12;
static NSString * const kWiFiSSIDReuseID = @"wifiSSIDReuseID";
static NSString * const kPasswordReuseID = @"passwordReuseID";

@interface SHSetupWiFiViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

@property (weak, nonatomic) UITextField *ssidTextField;
@property (weak, nonatomic) UITextField *pwdTextField;

@end

@implementation SHSetupWiFiViewController

+ (instancetype)setupWiFiViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Setup" bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"SHSetupWiFiVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
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
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = NSLocalizedString(@"kSetupConnectWifi", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_nextButton title:NSLocalizedString(@"kNext", nil)];
    
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_nextButton setBorderWidth:1.0 borderColor:_nextButton.titleLabel.textColor];
    
    [self updateTextFieldPropertyByAppLanguage];
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

- (void)updateSSIDStatus {
    [self setupSSID];
}

- (void)setupSSID {
    NSArray *array = [self getWifiSSID];
    
    _ssidTextField.text = array.firstObject;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)nextAction:(UIButton *)sender {
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
    if ([segue.identifier isEqualToString:@"go2TurnonCameraVCSegue"]) {
        SHTurnonCameraVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = nil;
    
    if (indexPath.row == 0) {
        cellIdentifier = kWiFiSSIDReuseID;
    } else if (indexPath.row == 1) {
        cellIdentifier = kPasswordReuseID;
    }
    
    SHSetupWiFiCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self getSubViewWithCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)getSubViewWithCell:(SHSetupWiFiCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        _ssidTextField = cell.ssidTextField;
        [self setupSSID];
    } else if (indexPath.row == 1) {
        _pwdTextField = cell.passwordTextField;
        [_pwdTextField becomeFirstResponder];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
