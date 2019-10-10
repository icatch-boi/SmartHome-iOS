// XJSetupDeviceInfoVC.m

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
 
 // Created by zj on 2018/5/21 下午5:37.
    

#import "XJSetupDeviceInfoVC.h"
#import "SHFindIndicator.h"
#import "SimpleLink.h"
#import "SHNetworkManagerHeader.h"
#import "Reachability.h"
#import "ZJSlidingDrawerViewController.h"
#import "SHQRCodeScanningVC.h"
#import "SHSetupNavVC.h"
#import "SHLocalWithRemoteHelper.h"
#import "SHWiFiInfoHelper.h"
#import "SHMessage.h"
#import "SHSetupHomeViewController.h"

static int const totalFindTime = 90;
static int const apmodeTimeout = 30;
static NSString * const kDeviceDefaultPassword = @"1234";

@interface XJSetupDeviceInfoVC ()

@property (weak, nonatomic) IBOutlet SHFindIndicator *findView;
@property (weak, nonatomic) IBOutlet UILabel *loadScaleLabel;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *configueDesLabel;

@property (assign, nonatomic) int findTimes;
@property (nonatomic) NSTimer *findTimer;
@property (nonatomic) NSTimeInterval findInterval;

@property (nonatomic) icatchtek::simplelink::SimpleLink *link;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, copy) NSString *cameraUid;

@property (nonatomic, strong) NSTimer *netStatusTimer;
@property (nonatomic, strong) SHCamera *savedCamera;
@property (nonatomic, assign) BOOL trying;

@property (nonatomic, assign) NSInteger tryConnectTimes;
@property (nonatomic, assign) BOOL linkSuccess;

@end

@implementation XJSetupDeviceInfoVC

- (void)setTryConnectTimes:(NSInteger)tryConnectTimes {
    @synchronized (self) {
        _tryConnectTimes = tryConnectTimes;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupLocalizedString];
    [self setupGUI];
    [self initParameter];
    
    [self selectSetupWay];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupLocalizedString {
    _loadingLabel.text = NSLocalizedString(@"kConfiguring1", nil);
    _tipsLabel.text = NSLocalizedString(@"Tips", nil);
    _configueDesLabel.text = NSLocalizedString(@"kConfigureDeviceDescription", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationBecomeActiveHandler) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationBecomeActiveHandler {
    if (self.linkSuccess) {
        [self netStatusTimer];
        [self findTimer];
    }
}

- (void)selectSetupWay {
    if (self.isAutoWay) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupNotificationHandle:) name:kSetupDeviceNotification object:nil];
        
        [self setupDevice];
        
        return;
    }
    
    if (_cameraUid != nil && _cameraUid.length > 0) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.cameraUid dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        dict ? [self shareHandle:dict] : [self setupDevice];
    } else {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kReconfigureDevice]) {
            [self setupDevice];
        }
    }
}

- (void)initParameter {
    _cameraUid = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
    _tryConnectTimes = 0;
    _linkSuccess = NO;
}

- (void)setupDevice {
    [_findView setBackgroundColor:self.view.backgroundColor];
    [_findView setStrokeColor:[UIColor ic_colorWithHex:kButtonThemeColor]];
    [_findView loadIndicator];
    
    [self findTimer];
    _findInterval = 100.0 / totalFindTime;
    if (self.isAutoWay == NO) {
        self.useQRCodeSetup == NO ? [self setupLink] : [self qrcodeSetupHandler];
    }
}

- (void)qrcodeSetupHandler {
    [self netStatusTimer];
    self.linkSuccess = YES;
}

- (void)setupGUI {
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[[UIImage imageNamed:@"nav-logo"] imageWithTintColor:[UIColor whiteColor]] gradient:NO];
    self.navigationItem.hidesBackButton = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_wifiPWD || _wifiSSID) {
        if (_link) {
            _link->cancel();
            delete _link;
            _link = nullptr;
        }
    }
    
    [self releaseTimer];
    [self releaseNetStatusTimer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

#pragma mark - SetupDevice
- (NSTimer *)findTimer {
    if (_findTimer == nil) {
        _findTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateViewStatus) userInfo:nil repeats:YES];
    }
    
    return _findTimer;
}

- (void)releaseTimer {
    if (_findTimer.valid) {
        [_findTimer invalidate];
        _findTimer = nil;
    }
}

- (void)updateViewStatus
{
    _findTimes++;
    int temp = _findInterval * _findTimes;
    
    [self updateProgressViewStatus:temp];
    
    if (temp >= 100) {
        [self releaseTimer];

        [self configureCameraTimeoutHandler];
        return;
    }
}

- (void)configureCameraTimeoutHandler {
    SHLogTRACE();
    self.findTimes = 0;
    [self releaseNetStatusTimer];
    
    if (self.linkSuccess) {
        NetworkStatus netStatus = [[Reachability reachabilityWithHostName:@"https://www.baidu.com"] currentReachabilityStatus];
        
        SHLogInfo(SHLogTagAPP, @"Current network status: %ld.", (long)netStatus);
        
        if (netStatus == NotReachable) {
            [self showNetworkNotReachableAlertView];
        } else {
            SHLogWarn(SHLogTagAPP, @"Configure camera timeout, current tryConnectTimes: %ld", (long)self.tryConnectTimes);
            
            if (self.tryConnectTimes == 0) {
                [self showConnectFailedTips];
            } else {
                self.tryConnectTimes = 0;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"action_waiting", nil)];
                });
            }
        }
    } else {
        [self showConfigureDeviceFailedAlertView];
    }
}

- (void)updateProgressViewStatus:(int)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        [_findView updateWithTotalBytes:100 downloadedBytes:value];
        
        _loadScaleLabel.text = [NSString stringWithFormat:@"%d%%", value];
        [self updateLoading];
    });
}

- (void)updateLoading {
    int temp = _findTimes % 3;
    NSString *title = nil;
    switch (temp) {
        case 0:
            title = NSLocalizedString(@"kConfiguring1", nil);
            break;
            
        case 1:
            title = NSLocalizedString(@"kConfiguring2", nil);
            break;
            
        default:
            title = NSLocalizedString(@"kConfiguring3", nil);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _loadingLabel.text = title;
    });
}

#pragma mark - Link
- (void)setupLink {
    NSString *ssid = _wifiSSID;
    NSString *pwd = _wifiPWD;
    SHLogInfo(SHLogTagAPP, @"set wifi ssid: %@, pwd: %@", ssid, pwd);
    
    if ([ssid isEqualToString:@""] || [pwd isEqualToString:@""]) {
        [self updateError:NSLocalizedString(@"kInvalidSSIDOrPassword", @"") error:0xff];
        return;
    }
    
    Boolean retValue = false;
    int flag = icatchtek::simplelink::SMARTLINK_V5;
    
    _link = new icatchtek::simplelink::SimpleLink;
    if (_link == NULL) {
        [self updateError:NSLocalizedString(@"kAPModeConnectFiled", @"") error:0xff];
        return;
    }
    
    NSString *cryptoKey = @"asdfghjklqwert++";
    retValue = _link->init(icatchtek::simplelink::LINKTYPE_APMODE, apmodeTimeout, 0, (char *)cryptoKey.UTF8String, 16, flag);
    if (retValue != icatchtek::simplelink::SIMPLELINK_ERR_OK) {
        [self updateError:NSLocalizedString(@"kAPModeConnectFiled", @"") error:retValue];
        return;
    }
    
    NSString *cameraUID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
    cameraUID = (cameraUID == nil) ? @"" : cameraUID;
    SHLogInfo(SHLogTagAPP, @"camera uid is : %@", cameraUID);
    retValue = _link->setContent(ssid.UTF8String, pwd.UTF8String, kDeviceDefaultPassword.UTF8String, "0.0.0.0", "0.0.0.0", "00:00:00:00:00:00", cameraUID.UTF8String);
    if (retValue != icatchtek::simplelink::SIMPLELINK_ERR_OK) {
        [self updateError:NSLocalizedString(@"kAPModeConnectFiled", @"") error:retValue];
        return;
    }
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"action_waiting", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //wait for receive uid from fw!
        string content = "";
        SHLogInfo(SHLogTagAPP,@"simpleconfig_get");
        
        int retVal = _link->link(content);
        _link->cancel();
        SHLogInfo(SHLogTagAPP, @"link is success: %d", retVal);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            
            if (!retVal) {
                if (content != "" && _cameraUid == nil) {
                    [self parseRecvContent:content];
                }
                [self netStatusTimer];
                self.linkSuccess = YES;
            } else {
                [self showConfigureDeviceFailedAlertView];
                self.linkSuccess = NO;
                [self releaseTimer];
            }
        });
    });
}

- (void)parseRecvContent:(string)content {
    int parseResult = 0;
    NSString *token = [[SHQRManager sharedQRManager] getTokenFromQRString:[NSString stringWithFormat:@"%s", content.c_str()] parseResult:&parseResult];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (uid != nil) {
        SHLogInfo(SHLogTagAPP, @"Recv uid: %@", uid);
        self.cameraUid = uid;
    }
}

- (void)updateError:(NSString *)header error:(int)err {
    
    NSString *e = nil;
    NSString *ss = nil;
    
    if (err == 0xff) {
        ss = [NSString stringWithFormat:@"%@", header];
    } else {
        e = [self errorString:err];
        ss = [NSString stringWithFormat:@"%@ With Error <%@>", header, e];
    }
    
    [self showWarningAlertDialog:ss];
}

- (NSString *)errorString:(int)error {
    NSString *str = nil;
    
    switch(error) {
            
        default:
            str = @"Unknown Error";
            break;
    }
    
    return str;
}

#pragma mark - show warning dialog
- (void)showWarningAlertDialog:(NSString*)warningMessage {
    if([warningMessage isEqualToString:@""] == YES) {
        SHLogWarn(SHLogTagAPP, @"showWarningAlertDialog :: No Message To Show");
        return;
    }
    
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^() {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"")
                                                                                message:warningMessage
                                                                         preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [controller dismissViewControllerAnimated:YES completion:nil];
            }];
            [controller addAction:action];
            [self presentViewController:controller animated:YES completion:nil];
        });
    }
}

#pragma mark - CheckNetworkStatus
- (NSTimer *)netStatusTimer {
    if (_netStatusTimer == nil) {
        _netStatusTimer = [NSTimer scheduledTimerWithTimeInterval:kNetworkDetectionInterval target:self selector:@selector(checkNetworkStatus) userInfo:nil repeats:YES];
    }
    
    return _netStatusTimer;
}

- (void)releaseNetStatusTimer {
    if ([_netStatusTimer isValid]) {
        [_netStatusTimer invalidate];
        _netStatusTimer = nil;
    }
}

- (void)checkNetworkStatus {
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        NetworkStatus netStatus = [[Reachability reachabilityWithHostName:@"https://www.baidu.com"] currentReachabilityStatus];
        
        if (netStatus == NotReachable) {
            SHLogWarn(SHLogTagAPP, @"Current network Unreachable.");
        } else {
            [self releaseNetStatusTimer];
            
            [self tryConnectDevice:-1];
        }
    });
}

- (void)tryConnectDevice:(NSInteger)tryTimes {
    if (_trying) {
        return;
    }
    
    self.tryConnectTimes = (tryTimes <= 0) ? 40 : tryTimes;
//    NSUInteger tryTimes = 40;//5;
    NSTimeInterval sleepTime = 5.0;
    _trying = YES;
    
    while (_tryConnectTimes > 0) {
        if ([self checkDeviceConnectState]) {
            break;
        } else {
            self.tryConnectTimes -= 1;

            [NSThread sleepForTimeInterval:sleepTime];
            (sleepTime > 1.0) ? sleepTime -- : sleepTime;
        }
    }
    
    _trying = NO;
    if (_tryConnectTimes <= 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showConnectFailedTips];
        });
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
    });
}

- (BOOL)checkDeviceConnectState {
    BOOL connectSuccess = NO;
    
    SHSDK *sdk = [[SHSDK alloc] init];

    
    int retVal = [sdk tryConnectCamera:_cameraUid devicePassword:kDeviceDefaultPassword];

    if (retVal == ICH_SUCCEED) {
        connectSuccess = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] boolForKey:kReconfigureDevice] ? [self reconfigureDeviceHandle] : [self showAddDeviceTips];
        });

        [sdk destroyTryConnectResource];

        [self releaseTimer];
        [[SHWiFiInfoHelper sharedWiFiInfoHelper] addWiFiInfo:_wifiSSID password:_wifiPWD];
    } else {
        SHLogError(SHLogTagAPP, @"checkDeviceConnectState is failed, retVal: %d, tryConnectTimes: %ld", retVal, (long)self.tryConnectTimes);
    }
    
    return connectSuccess;
}

- (void)showAddDeviceTips {
    _loadingLabel.text = NSLocalizedString(@"kConfigureSuccess", nil);
    __block NSString *cameraName = [_cameraUid substringToIndex:5];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kConfigureSuccess", nil) message:NSLocalizedString(@"kSetDeviceName", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *deviceNameField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.text = cameraName;
        
        deviceNameField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([SHTool isValidDeviceName:deviceNameField.text] == NO) {
            [weakself showDeviceNameInvalidAlertView:^{
                [weakself showAddDeviceTips];
            }];
            return;
        }
        
        if (![deviceNameField.text isEqualToString:@""]) {
            cameraName = deviceNameField.text;
        }
        
        [weakself addCameraWithName:cameraName];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showDeviceNameInvalidAlertView:(void (^)(void))finishedBlock {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:[NSString stringWithFormat:NSLocalizedString(@"kDeviceNameInvalidDescription", nil), (unsigned long)kDeviceNameMinLength, (unsigned long)kDeviceNameMaxLength] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if (finishedBlock) {
            finishedBlock();
        }
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showConnectFailedTips {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kTryToConnectDeviceFailed", nil) message:NSLocalizedString(@"kTryToConnectDeviceFailedDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kTryagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself releaseTimer];
        
        [weakself.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"action_waiting", nil)];
        dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
            [weakself tryConnectDevice:1];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showConfigureDeviceFailedAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kConfigureDeviceFailed", nil) message:NSLocalizedString(@"kConfigureDeviceFailedDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kTryagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself releaseTimer];
#if 0
            [weakself scanQRCode];
#else
            [weakself presentSetupHomeVC];
#endif
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)scanQRCode {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    [self presentQRCodeScanningVC];
                    
                    SGQRCodeLog(@"当前线程 - - %@", [NSThread currentThread]);
                    // 用户第一次同意了访问相机权限
                    SGQRCodeLog(@"用户第一次同意了访问相机权限");
                    
                } else {
                    
                    // 用户第一次拒绝了访问相机权限
                    SGQRCodeLog(@"用户第一次拒绝了访问相机权限");
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问相机
            [self presentQRCodeScanningVC];
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问相机
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kCameraAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
            
        } else if (status == AVAuthorizationStatusRestricted) {
            SHLogError(SHLogTagAPP, @"因为系统原因, 无法访问相册");
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kCameraNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)presentQRCodeScanningVC {
    SHQRCodeScanningVC *vc = [[SHQRCodeScanningVC alloc] init];
    SHSetupNavVC *nav = [[SHSetupNavVC alloc] initWithRootViewController:vc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC presentViewController:nav animated:YES completion:nil];
    });
}

- (void)presentSetupHomeVC {
    SHSetupHomeViewController *vc = [SHSetupHomeViewController setupHomeViewController];
    SHSetupNavVC *nav = [[SHSetupNavVC alloc] initWithRootViewController:vc];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC presentViewController:nav animated:YES completion:nil];
    });
}

#pragma mark - ShareCameraHander
- (void)shareHandle:(NSDictionary *)dict {
    NSString *shareDeadline = dict[@"shareDeadline"];
    NSTimeInterval deadline = [shareDeadline doubleValue];
    
    if (deadline && (deadline < [[NSDate date] timeIntervalSince1970])) {
        [self showQRCodeExpireAlertView];
    } else {
        [self showSubscribeCameraAlertView:dict];
    }
}

- (void)showSubscribeCameraAlertView:(NSDictionary *)dict {
    NSString *accountName = dict[@"accountName"];
    NSString *message = accountName ? [NSString stringWithFormat:NSLocalizedString(@"kSureSubscribeSomeoneDevice", nil), accountName] : NSLocalizedString(@"kSureSubscribeNewDevice", nil);
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *deviceNameField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.placeholder = NSLocalizedString(@"kDeviceName", nil);
        
        deviceNameField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([SHTool isValidDeviceName:deviceNameField.text] == NO) {
            [weakself showDeviceNameInvalidAlertView:^{
                [self showSubscribeCameraAlertView:dict];
            }];
            return;
        }
        
        if (![deviceNameField.text isEqualToString:@""]) {
            NSString *cameraName = deviceNameField.text;
            [[NSUserDefaults standardUserDefaults] setObject:cameraName forKey:kSubscribeCameraName];
        }
        
        [weakself subscribeCamera:dict];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)subscribeCamera:(NSDictionary *)dict {
    if (dict == nil || dict[@"cameraId"] == nil || dict[@"invitationCode"] == nil) {
        SHLogError(SHLogTagAPP, @"dict may is nil, dict: %@", dict);
        
        [self showFailedAlertViewWithTitle:NSLocalizedString(@"kSubscribeFailed", nil) message:nil];
        
        return;
    }
    
    [self subscribeCameraHandler:dict];
}

- (void)subscribeCameraHandler:(NSDictionary *)dict {
    NSString *cameraId = dict[@"cameraId"];
    NSString *invitationCode = dict[@"invitationCode"];
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        WEAK_SELF(self);
        [[SHNetworkManager sharedNetworkManager] subscribeCameraWithCameraID:cameraId cameraName:[[NSUserDefaults standardUserDefaults] objectForKey:kSubscribeCameraName] invitationCode:invitationCode completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"Subscribe camera is success: %d", isSuccess);
            
            if (isSuccess) {
                [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:cameraId completion:^(BOOL isSuccess, id  _Nonnull result) {
                    SHLogInfo(SHLogTagAPP, @"Get camera is success: %d", isSuccess);
                    
                    if (isSuccess) {
                        [weakself addCamera2LocalSqlite:result];
                        [SHLocalWithRemoteHelper getThumbnailWithdeviceInfo:result];
                    } else {
                        Error *error = result;
                        SHLogError(SHLogTagAPP, @"Get camera is failed, error: %@", error.error_description);
                        
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakself.progressHUD hideProgressHUD:YES];
                            
                            [weakself showFailedAlertViewWithTitle:NSLocalizedString(@"kGetDeviceFailed", nil) message:[SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]];
                        });
                    }
                }];
            } else {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"Subscribe camera is failed, error: %@", error.error_description);
                
                [weakself showSubscribeCameraFailedAlertView:dict];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                });
            }
        }];
    });
}

- (void)showSubscribeCameraFailedAlertView:(NSDictionary *)dict {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kConnectionAccountServerFailed", nil) message:NSLocalizedString(@"kConnectionAccountServerFailedDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [weakself dismissSetupView];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kTryagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself subscribeCameraHandler:dict];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

- (void)showQRCodeExpireAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kShareQRCodeExpired", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)addCamera2LocalSqlite:(Camera *)camera_server {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUid = %@", camera_server.uid];
    [fetchRequest setPredicate:predicate];
    
    int operable = [self isOperableWithOwnerID:camera_server.ownerId];

    BOOL isExist = NO;
    NSError *error = nil;
    NSArray *fetchedObjects = [[CoreDataHandler sharedCoreDataHander].managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        SHLogWarn(SHLogTagAPP, @"Already have one camera: %@", camera_server.uid);
        isExist = YES;
        
        SHCamera *camera = fetchedObjects.firstObject;
        camera.cameraName = [[NSUserDefaults standardUserDefaults] objectForKey:kSubscribeCameraName];
        camera.cameraUid = camera_server.uid;
        camera.devicePassword = camera_server.devicepassword;
        camera.id = camera_server.id;
        camera.operable = operable;
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd HHmmss"];
        camera.createTime = [df stringFromDate:[NSDate date]];

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
#if 0
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            });
#endif
        }
    } else {
        SHLogInfo(SHLogTagAPP, @"Create a camera");
        SHCamera *savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
        savedCamera.cameraName = [[NSUserDefaults standardUserDefaults] objectForKey:kSubscribeCameraName];
        savedCamera.cameraUid = camera_server.uid;
        savedCamera.devicePassword = camera_server.devicepassword;
        savedCamera.id = camera_server.id;
        savedCamera.operable = operable;
#if 0
        NSDate *date = [NSDate date];
        NSTimeInterval sec = [date timeIntervalSinceNow];
        NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd HHmmss"];
        savedCamera.createTime = [df stringFromDate:currentDate];
        SHLogInfo(SHLogTagAPP, @"Create time is %@", savedCamera.createTime);
#else
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd HHmmss"];
        savedCamera.createTime = [df stringFromDate:[NSDate date]];
#endif
        // Save data to sqlite
        NSError *error = nil;
        if (![savedCamera.managedObjectContext save:&error]) {
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
        [self.progressHUD hideProgressHUD:YES];
        [self dismissSetupView];
    });
}

- (void)addCameraWithName:(NSString *)cameraName {
    if (self.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        [self showConfigureDeviceFailedAlertView];
        return;
    }
    
    if (cameraName == nil) {
        cameraName = [self.cameraUid substringToIndex:5];
    }
    
    [self bindDeviceToServerWithUid:self.cameraUid name:cameraName];
}

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
                    weakself.savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
                    weakself.savedCamera.cameraUid = cameraUid;
                    weakself.savedCamera.cameraName = cameraName;
                    weakself.savedCamera.devicePassword = kDeviceDefaultPassword;
                    weakself.savedCamera.id = camera_server.id;
                    weakself.savedCamera.operable = operable;
#if 0
                    NSDate *date = [NSDate date];
                    NSTimeInterval sec = [date timeIntervalSinceNow];
                    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
                    
                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyyMMdd HHmmss"];
                    self.savedCamera.createTime = [df stringFromDate:currentDate];
                    SHLogInfo(SHLogTagAPP, @"Create time is %@", weakself.savedCamera.createTime);
#else
                    weakself.savedCamera.createTime = [SHTool localDBTimeStringFromServer:camera_server.time];
#endif
                    // Save data to sqlite
                    NSError *error = nil;
                    if (![weakself.savedCamera.managedObjectContext save:&error]) {
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
                        [SHTutkHttp registerDevice:weakself.savedCamera];
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

- (void)bindDeviceFailedHandler:(Error *)error {
    NSString *title = NSLocalizedString(@"kBindDeviceFailed", nil);
    NSString *message = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code];

    if (error.error_code == 50034) {
        message = NSLocalizedString(@"kDeviceBindByOtherAccounts", nil);
    }
    
    [self showFailedAlertViewWithTitle:title message:message];
}

- (void)showFailedAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself dismissSetupView];
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

#pragma mark - Check Network Reachable
- (void)showNetworkNotReachableAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kNetworkNotReachable", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself dismissSetupView];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kToSetup", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself setupDeviceWiFi];
            
            [weakself updateProgressViewStatus:0];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)setupDeviceWiFi {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kEnterAPMode];
    
    [SHTool appToSystemSettings];
}

- (void)reconfigureDeviceHandle {
    _loadingLabel.text = NSLocalizedString(@"kConfigureSuccess", nil);
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kConfigureSuccess", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)setupNotificationHandle:(NSNotification *)nc {
    [self releaseTimer];

    SHMessage *message = nc.object;
    int msgType = message.msgType.intValue;
    switch (msgType) {
        case 1201:
            [self showAddDeviceViewWithDeviceID:message.deviceId];
            break;
            
        case 1202: {
            NSString *msg = message.msgParam;
            
            if (message.errCode.intValue == 50034) {
                if (message.deviceId != nil) {
                    msg = NSLocalizedString(@"kDeviceAlreadyExist", nil);
                } else {
                    msg = NSLocalizedString(@"kDeviceBindByOtherAccounts", nil);
                }
            }
            
            [self showFailedAlertViewWithTitle:NSLocalizedString(@"kConfigureDeviceFailed", nil) message:msg];
        }
            break;
            
        default:
            break;
    }
}

- (void)showAddDeviceViewWithDeviceID:(NSString *)deviceID {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"`deviceID` is nil.");

        [self showConfigureDeviceFailedAlertView];
        return;
    }
    
    _loadingLabel.text = NSLocalizedString(@"kConfigureSuccess", nil);
    __block NSString *cameraName = nil;
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kConfigureSuccess", nil) message:NSLocalizedString(@"kSetDeviceName", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *deviceNameField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.text = cameraName;
        
        deviceNameField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([SHTool isValidDeviceName:deviceNameField.text] == NO) {
            [weakself showDeviceNameInvalidAlertView:^{
                [weakself showAddDeviceViewWithDeviceID:deviceID];
            }];
            return;
        }
        
        if (![deviceNameField.text isEqualToString:@""]) {
            cameraName = deviceNameField.text;
        }
        
        [weakself setupDeviceNameWithDeviceID:deviceID deviceName:cameraName];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)setupDeviceNameWithDeviceID:(NSString *)deviceID deviceName:(NSString *)deviceName {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kConfigureDeviceInfo", nil)];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] renameCameraByCameraID:deviceID andNewName:deviceName completion:^(BOOL isSuccess, id  _Nonnull result) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUD hideProgressHUD:YES];

            if(isSuccess) {
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
                [[SHWiFiInfoHelper sharedWiFiInfoHelper] addWiFiInfo:weakself.wifiSSID password:weakself.wifiPWD];

                [weakself.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            } else {
                [weakself showSetupDeviceNameFailedAlertWithDeviceID:deviceID deviceName:deviceName];
            }
        });
    }];
}

- (void)showSetupDeviceNameFailedAlertWithDeviceID:(NSString *)deviceID deviceName:(NSString *)deviceName {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"设置设备名称失败，需要重新尝试吗？" preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kTryagain", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself setupDeviceNameWithDeviceID:deviceID deviceName:deviceName];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

@end
