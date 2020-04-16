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
#import <SystemConfiguration/CaptiveNetwork.h>
#import "XJSetupDeviceSSIDVC.h"
#import "UnderLineTextField.h"
#import "Reachability.h"
#import "SHQRCodeSetupDeviceVC.h"
#import "SHWiFiInfoHelper.h"
#import <CoreLocation/CoreLocation.h>
#import "SHNetworkManagerHeader.h"

static NSString * const kDeviceDefaultPassword = @"1234";

@interface XJSetupWiFiVC () <XJSetupTipsViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UnderLineTextField *ssidTextField;
@property (weak, nonatomic) IBOutlet UnderLineTextField *pwdTextField;

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (weak, nonatomic) IBOutlet UIButton *changePasswordBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *exitButtonItem;
@property (weak, nonatomic) IBOutlet UIButton *qrcodeButton;
@property (nonatomic, assign) BOOL qrcodeSetup;

@property (nonatomic, strong) XJSetupTipsView *tipsView;
@property (nonatomic, weak) UIView *coverView;

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, copy) NSString *cameraUid;

@end

@implementation XJSetupWiFiVC

+ (instancetype)setupWiFiVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"XJSetupWiFiVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupLocalizedString];
    [self setupGUI];
    _cameraUid = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
}

- (void)setupLocalizedString {
    _titleLabel.text = NSLocalizedString(@"kSelectWiFiDescription", nil);
    _ssidTextField.placeholder = NSLocalizedString(@"kWifiSSID", nil);
    _pwdTextField.placeholder = NSLocalizedString(@"kWifiPassword", nil);
    [_changePasswordBtn setTitle:NSLocalizedString(@"kChangeWiFiDescription", nil) forState:UIControlStateNormal];
    [_changePasswordBtn setTitle:NSLocalizedString(@"kChangeWiFiDescription", nil) forState:UIControlStateHighlighted];
    [_nextButton setTitle:NSLocalizedString(@"kUseAPModeSetupDevice", nil) forState:UIControlStateNormal];
    [_nextButton setTitle:NSLocalizedString(@"kUseAPModeSetupDevice", nil) forState:UIControlStateHighlighted];
    [_exitButtonItem setTitle:NSLocalizedString(@"kExit", nil)];
    
    [_changePasswordBtn layoutIfNeeded];
    
    [_qrcodeButton setTitle:NSLocalizedString(@"kUseQRCodeSetupDevice", nil) forState:UIControlStateNormal];
    [_qrcodeButton setTitle:NSLocalizedString(@"kUseQRCodeSetupDevice", nil) forState:UIControlStateHighlighted];
}

- (void)setupGUI {
//    [self.navigationController.view addSubview:[self coverView]];
    
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.25 masksToBounds:NO];
    
    _ssidTextField.delegate = self;
    _pwdTextField.delegate = self;
    
    UIColor *color = [UIColor ic_colorWithHex:kButtonThemeColor];
    _ssidTextField.lineColor = color;
    _pwdTextField.lineColor = color;
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
        [self requestLocationPermission];
    } else {
        [self setupSSID];
    }
    
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[[UIImage imageNamed:@"nav-logo"] imageWithTintColor:[UIColor whiteColor]] gradient:NO];
    [self addLineForChangePasswordBtn];
    _titleLabel.textColor = [UIColor ic_colorWithHex:kTextThemeColor];
    
    _ssidTextField.enabled = NO;
    
    [_pwdTextField addTarget:self action:@selector(updateButtonEnableState) forControlEvents:UIControlEventEditingChanged];
    [self updateButtonEnableState];
    _pwdTextField.secureTextEntry = NO;
    
    if (self.isConfigWiFi) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(closeAction) isBack:NO];
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    [self addLongPressGesture];
}

- (void)closeAction {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)addLineForChangePasswordBtn {
    [_changePasswordBtn setTintColor:[UIColor ic_colorWithHex:kTextThemeColor]];
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, _changePasswordBtn.frame.size.height - 5, _changePasswordBtn.frame.size.width, 1)];
    line.backgroundColor = _changePasswordBtn.currentTitleColor;
    
    [_changePasswordBtn addSubview:line];
}

- (void)setupSSID {
    NSArray *array = [self getWifiSSID];
    
    _ssidTextField.text = array.firstObject;
    _pwdTextField.text = [[SHWiFiInfoHelper sharedWiFiInfoHelper] passwordForSSID:array.firstObject];
    [self updateButtonEnableState];
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
    if ([UIDevice currentDevice].systemVersion.floatValue >= 13.0) {
        [self requestLocationPermission];
    } else {
        [self setupSSID];
    }
    [self updateButtonEnableState];
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
    self.qrcodeSetup = NO;
    [self verifyWiFiSetup];
}

- (IBAction)qrcodeSetupClick:(id)sender {
    self.qrcodeSetup = YES;
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
    NSRange pwdRange = [_pwdTextField.text rangeOfString:@"[A-Za-z0-9_()?![，。？：；’‘！”“、`~!@#$%^&*()-_=+<>./]]{8,63}" options:NSRegularExpressionSearch];
    
    if (ssidRange.location == NSNotFound || pwdRange.location == NSNotFound) {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kInvalidSSIDOrPassword", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:nil]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertC animated:YES completion:nil];
        });
    } else {
#if 0
        [self performSegueWithIdentifier:@"go2SetupDeviceSSIDVCSegue" sender:nil];
#else
        [self showSurePasswordAlertView];
#endif
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2SetupDeviceSSIDVCSegue"]) {
        XJSetupDeviceSSIDVC *vc = segue.destinationViewController;

        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
    } else if ([segue.identifier isEqualToString:@"go2QRCodeSetupDeviceVCSegue"]) {
        SHQRCodeSetupDeviceVC *vc = segue.destinationViewController;
        
        vc.wifiSSID = _ssidTextField.text;
        vc.wifiPWD = _pwdTextField.text;
        vc.autoWay = self.isAutoWay;
        vc.configWiFi = self.isConfigWiFi;
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
        
        return nil;
    } else return @[mssid,mmac];
}

- (void)setupDeviceWiFi {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kEnterAPMode];

    [SHTool appToSystemSettings];
}

#pragma mark - UITextFiledDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Check Network Reachable
- (void)showSurePasswordAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kMakeSureWiFiNameAndPassword", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self checkNetworkStatus];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)checkNetworkStatus {
    NetworkStatus netStatus = [[Reachability reachabilityWithHostName:@"https://www.baidu.com"] currentReachabilityStatus];
    
    if (netStatus == NotReachable) {
        SHLogWarn(SHLogTagAPP, @"Current network Unreachable.");

        [self showNetworkNotReachableAlertView:NSLocalizedString(@"kNetworkNotReachable", nil)];
    } else if (netStatus == ReachableViaWWAN) {
        [self showNetworkNotReachableAlertView:NSLocalizedString(@"kWiFiNotReachable", nil)];
    } else {
        if (self.qrcodeSetup) {
            [self performSegueWithIdentifier:@"go2QRCodeSetupDeviceVCSegue" sender:nil];
            return;
        }
        [self performSegueWithIdentifier:@"go2SetupDeviceSSIDVCSegue" sender:nil];
    }
}

- (void)showNetworkNotReachableAlertView:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupDeviceWiFi];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)updateButtonEnableState {
    _nextButton.enabled = ![_ssidTextField.text isEqualToString:@""] && ![_pwdTextField.text isEqualToString:@""] && !self.isAutoWay;
    _qrcodeButton.enabled = ![_ssidTextField.text isEqualToString:@""] && ![_pwdTextField.text isEqualToString:@""];
}

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
        case  kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
            [self showLocationAuthorizationAlertView];
            break;
            
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [self setupSSID];
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

#pragma mark - LongPress Gesture
- (void)addLongPressGesture {
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    longPress.minimumPressDuration = 2.0;
    [_iconImageView addGestureRecognizer:longPress];
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"longPressGesture");
    [self bindDeviceToServerWithUid:self.cameraUid name:[self.cameraUid substringToIndex:5]];
}

#pragma mark - Bind Device
- (void)bindDeviceToServerWithUid:(NSString *)cameraUid name:(NSString *)cameraName {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kConfigureDeviceInfo", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
        [fetchRequest setEntity:entity];
        
        WEAK_SELF(self);
        [[SHNetworkManager sharedNetworkManager] bindCameraWithCameraUid:cameraUid name:cameraName password:kDeviceDefaultPassword completion:^(BOOL isSuccess, id result) {
            SHLogInfo(SHLogTagAPP, @"bindCmaera is success: %d", isSuccess);
            
            if (isSuccess) {
                Camera *camera_server = result;
                int operable = [weakself isOperableWithOwnerID:camera_server.ownerId];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUid = %@", cameraUid];
                [fetchRequest setPredicate:predicate];
                
                BOOL isExist = NO;
                NSError *error = nil;
                NSArray *fetchedObjects = [[CoreDataHandler sharedCoreDataHander].managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (!error && fetchedObjects && fetchedObjects.count > 0) {
                    SHLogWarn(SHLogTagAPP, @"Already have one camera: %@", cameraUid);
                    isExist = YES;
                    
                    SHCamera *camera = fetchedObjects.firstObject;
                    camera.cameraName = cameraName;
                    camera.cameraUid = camera_server.uid;
                    camera.devicePassword = kDeviceDefaultPassword;
                    camera.id = camera_server.id;
                    camera.operable = operable;
                    
                    camera.createTime = [SHTool localDBTimeStringFromServer:camera_server.time];

                    // Save data to sqlite
                    NSError *error = nil;
                    if (![camera.managedObjectContext save:&error]) {
                        SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                        abort();
#endif
                    } else {
                        SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NeedReloadDataBase"];
                        [SHTutkHttp registerDevice:camera];
                    }
                } else {
                    SHLogInfo(SHLogTagAPP, @"Create a camera");
                    SHCamera *savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
                    savedCamera.cameraUid = cameraUid;
                    savedCamera.cameraName = cameraName;
                    savedCamera.devicePassword = kDeviceDefaultPassword;
                    savedCamera.id = camera_server.id;
                    savedCamera.operable = operable;
                    
                    savedCamera.createTime = [SHTool localDBTimeStringFromServer:camera_server.time];
                    
                    // Save data to sqlite
                    NSError *error = nil;
                    if (![savedCamera.managedObjectContext save:&error]) {
                        /*
                         Replace this implementation with code to handle the error appropriately.
                         
                         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                         */
                        SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                        abort();
#endif
                    } else {
                        SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NeedReloadDataBase"];
                        [SHTutkHttp registerDevice:savedCamera];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    [weakself.navigationController.topViewController dismissViewControllerAnimated:YES completion:^{
                        if (isExist) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kCameraAlreadyExistNotification object:cameraName];
                        }
                    }];
                });
            } else {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"bindCmaera is failed, error: %@", error.error_description);
                
                [weakself showBindDeviceFailedAlertViewWithName:cameraName];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                });
            }
        }];
    });
}

- (int)isOperableWithOwnerID:(NSString *)ownerId {
    int operable = 1;
    
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    
    if (![ownerId isEqualToString:owner]) {
        operable = 0;
    }
    
    return operable;
}

- (void)showBindDeviceFailedAlertViewWithName:(NSString *)cameraName {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kConnectionAccountServerFailed", nil) message:NSLocalizedString(@"kConnectionAccountServerFailedDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakself dismissSetupView];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kTryagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself bindDeviceToServerWithUid:weakself.cameraUid name:cameraName];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

- (void)dismissSetupView {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
    });
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.navigationController.view];
    }
    
    return _progressHUD;
}

@end
