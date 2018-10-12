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
#import "SimpleLinkErrorID.h"
#import "SHNetworkManagerHeader.h"
#import "Reachability.h"
#import "ZJSlidingDrawerViewController.h"
#import "SHQRCodeScanningVC.h"
#import "SHSetupNavVC.h"

static int const totalFindTime = 90;
static int const apmodeTimeout = 30;
static NSString * const kDeviceDefaultPassword = @"1234";

@interface XJSetupDeviceInfoVC ()

@property (weak, nonatomic) IBOutlet SHFindIndicator *findView;
@property (weak, nonatomic) IBOutlet UILabel *loadScaleLabel;
@property (weak, nonatomic) IBOutlet UILabel *loadingLabel;

@property (assign, nonatomic) int findTimes;
@property (nonatomic) NSTimer *findTimer;
@property (nonatomic) NSTimeInterval findInterval;

@property (nonatomic) icatchtek::simplelink::SimpleLink *link;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, copy) NSString *cameraUid;

@property (nonatomic, strong) NSTimer *netStatusTimer;
@property (nonatomic, strong) SHCamera *savedCamera;
@property (nonatomic, assign) BOOL trying;

@end

@implementation XJSetupDeviceInfoVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [self initParameter];
    
    [self selectSetupWay];
}

- (void)selectSetupWay {
    if (_cameraUid != nil && _cameraUid.length > 0) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.cameraUid dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
        dict ? [self shareHandle:dict] : [self setupDevice];
    }
}

- (void)initParameter {
    _cameraUid = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
}

- (void)setupDevice {
    [_findView setBackgroundColor:self.view.backgroundColor];
    [_findView setStrokeColor:[UIColor ic_colorWithHex:kButtonThemeColor]];
    [_findView loadIndicator];
    
    [self findTimer];
    _findInterval = 100.0 / totalFindTime;
    [self setupLink];
}

- (void)setupGUI {
    self.navigationItem.titleView = [UIImageView imageViewWithImage:[UIImage imageNamed:@"nav-logo"] gradient:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_wifiPWD || _wifiSSID) {
        _link->cancel();
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
    
    [_findView updateWithTotalBytes:100 downloadedBytes:temp];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _loadScaleLabel.text = [NSString stringWithFormat:@"%d%%", temp];
        [self updateLoading];
    });
    
    if (temp >= 100) {
        [self releaseTimer];
        [self showConnectFailedTips];
        return;
    }
}

- (void)updateLoading {
    int temp = _findTimes % 3;
    NSString *title = nil;
    switch (temp) {
        case 0:
            title = @"Loading .";
            break;
            
        case 1:
            title = @"Loading ..";
            break;
            
        default:
            title = @"Loading ...";
            break;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _loadingLabel.text = title;
    });
}

#pragma mark - Link
- (void)setupLink {
    NSString *ssid = _wifiSSID; //self.ssidTextField.text;
    NSString *pwd = _wifiPWD; //self.pwdTextField.text;
    
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
    
    NSString *cryptoKey = @"asdfghjklqwert++"; //@"1234567890Abcdef";
    retValue = _link->init(icatchtek::simplelink::LINKTYPE_APMODE, apmodeTimeout, 0, (char *)cryptoKey.UTF8String, 16, flag);
    if (retValue != SIMPLELINK_ERR_OK) {
        [self updateError:NSLocalizedString(@"kAPModeConnectFiled", @"") error:retValue];
        return;
    }
    
    NSString *cameraUID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentAddCameraUID];
    SHLogInfo(SHLogTagAPP, @"camera uid is : %@", cameraUID);
    retValue = _link->setContent(ssid.UTF8String, pwd.UTF8String, kDeviceDefaultPassword.UTF8String, "0.0.0.0", "0.0.0.0", "00:00:00:00:00:00", cameraUID.UTF8String);
    if (retValue != SIMPLELINK_ERR_OK) {
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            
            if (!retVal) {
//                _cameraUid = [NSString stringWithFormat:@"%s", content.c_str()];
                
                [self netStatusTimer];
            } else {
                [self showConnectFailedTips];
            }
        });
    });
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
        NSLog(@"showWarningAlertDialog :: No Message To Show");
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
            
        } else {
            [self releaseNetStatusTimer];
            
            [self tryConnectDevice];
        }
    });
}

- (void)tryConnectDevice {
    if (_trying) {
        return;
    }
    
    NSUInteger tryTimes = 40;//5;
    NSTimeInterval sleepTime = 5.0;
    _trying = YES;
    
    while (tryTimes > 0) {
        if ([self checkDeviceConnectState]) {
            break;
        } else {
            tryTimes --;
#if 0
            [NSThread sleepForTimeInterval:20.0];
#else
            [NSThread sleepForTimeInterval:sleepTime];
            (sleepTime > 1.0) ? sleepTime -- : sleepTime;
#endif
        }
    }
    
    _trying = NO;
    if (tryTimes == 0) {
        [self showConnectFailedTips];
    }
}

- (BOOL)checkDeviceConnectState {
    BOOL connectSuccess = NO;
    
    SHSDK *sdk = [[SHSDK alloc] init];
#if 0
    int retVal = [sdk initializeSHSDK:_cameraUid devicePassword:kDeviceDefaultPassword];
#else
    int retVal = [sdk tryConnectCamera:_cameraUid devicePassword:kDeviceDefaultPassword];
#endif
    if (retVal == ICH_SUCCEED) {
        connectSuccess = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showAddDeviceTips];
        });
#if 0
        [sdk destroySHSDK];
#else
        [sdk destroyTryConnectResource];
#endif
        [self releaseTimer];
    } else {
        SHLogError(SHLogTagAPP, @"checkDeviceConnectState is failed, retVal: %d", retVal);
    }
    
    return connectSuccess;
}

- (void)showAddDeviceTips {
    _loadingLabel.text = @"Success";
    __block NSString *cameraName = [_cameraUid substringToIndex:5];
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Success" message:@"Please set doorbell name" preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *deviceNameField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.text = cameraName;
        
        deviceNameField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (![deviceNameField.text isEqualToString:@""]) {
            cameraName = deviceNameField.text;
        }
        
        [weakself addCameraWithName:cameraName];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)showConnectFailedTips {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Failed" message:@"Please try again. Make sure password you entered is right." preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Try again" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
#if 0
        UIStoryboard *sb = [UIStoryboard storyboardWithName:kSetupStoryboardName bundle:nil];
        UINavigationController *nav = [sb instantiateInitialViewController];
        
        [weakself.navigationController dismissViewControllerAnimated:YES completion:^{
            [[ZJSlidingDrawerViewController sharedSlidingDrawerVC].mainVC presentViewController:nav animated:YES completion:nil];
        }];
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself scanQRCode];
            [weakself.navigationController dismissViewControllerAnimated:YES completion:nil];
        });
#endif
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
            NSLog(@"因为系统原因, 无法访问相册");
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
    NSString *message = accountName ? [NSString stringWithFormat:@"Sure you want to subscribe [%@] to share with your camera?", accountName] : @"Sure you want to subscribe to the new camera?";
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"Sure" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself subscribeCamera:dict];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)subscribeCamera:(NSDictionary *)dict {
    NSString *cameraId = dict[@"cameraId"];
    NSString *invitationCode = dict[@"invitationCode"];
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] subscribeCameraWithCameraID:cameraId invitationCode:invitationCode completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:cameraId completion:^(BOOL isSuccess, id  _Nonnull result) {
                    if (isSuccess) {
                        [self addCamera2LocalSqlite:result];
                    } else {
                        Error *error = result;
#if 0
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progressHUD.detailsLabelText = error.error_description;
                            [self.progressHUD showProgressHUDNotice:@"Failed to get the camera" showTime:2.0];
                            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                        });
#else
                        [self showFailedAlertViewWithTitle:@"Failed to get the camera" message:error.error_description];
#endif
                    }
                }];
            } else {
                Error *error = result;
#if 0
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressHUD.detailsLabelText = error.error_description;
                    [self.progressHUD showProgressHUDNotice:@"Subscribe to the failure" showTime:2.0];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                    });
                });
#else
                [self showFailedAlertViewWithTitle:@"Subscribe to the failure" message:error.error_description];
#endif
            }
        }];
    });
}

- (void)showQRCodeExpireAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Tips" message:@"Share the qr code has expired." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
//            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
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
        NSLog(@"Already have one camera: %@", camera_server.uid);
        isExist = YES;
        
        SHCamera *camera = fetchedObjects.firstObject;
        camera.cameraName = camera_server.name;
        camera.cameraUid = camera_server.uid;
        camera.devicePassword = camera_server.devicepassword;
        camera.id = camera_server.id;
        camera.operable = operable;
        
        // Save data to sqlite
        NSError *error = nil;
        if (![camera.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        } else {
            NSLog(@"Saved to sqlite.");
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
        NSLog(@"Create a camera");
        SHCamera *savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
        savedCamera.cameraName = camera_server.name;
        savedCamera.cameraUid = camera_server.uid;
        savedCamera.devicePassword = camera_server.devicepassword;
        savedCamera.id = camera_server.id;
        savedCamera.operable = operable;
        
        NSDate *date = [NSDate date];
        NSTimeInterval sec = [date timeIntervalSinceNow];
        NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
        
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd HHmmss"];
        savedCamera.createTime = [df stringFromDate:currentDate];
        NSLog(@"Create time is %@", savedCamera.createTime);
        
        // Save data to sqlite
        NSError *error = nil;
        if (![savedCamera.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        } else {
            NSLog(@"Saved to sqlite.");
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NeedReloadDataBase"];
            [SHTutkHttp registerDevice:savedCamera];
#if 0
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:@"订阅成功" showTime:2.0];
                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            });
#endif
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
        [self dismissSetupView];
    });
}

- (void)addCameraWithName:(NSString *)cameraName {
    NSString *cameraUid = _cameraUid;
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:@"Setup camera's Info..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
        [fetchRequest setEntity:entity];

        [[SHNetworkManager sharedNetworkManager] bindCameraWithCameraUid:cameraUid name:cameraName password:kDeviceDefaultPassword completion:^(BOOL isSuccess, id result) {
            NSLog(@"bindCmaera is success: %d", isSuccess);
            
            if (isSuccess) {
                Camera *camera_server = result;
                int operable = [self isOperableWithOwnerID:camera_server.ownerId];
                
                NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUid = %@", cameraUid];
                [fetchRequest setPredicate:predicate];
                
                BOOL isExist = NO;
                NSError *error = nil;
                NSArray *fetchedObjects = [[CoreDataHandler sharedCoreDataHander].managedObjectContext executeFetchRequest:fetchRequest error:&error];
                if (!error && fetchedObjects && fetchedObjects.count > 0) {
                    NSLog(@"Already have one camera: %@", cameraUid);
                    isExist = YES;
                    
                    SHCamera *camera = fetchedObjects.firstObject;
                    camera.cameraName = cameraName;
                    camera.cameraUid = camera_server.uid;
                    camera.devicePassword = kDeviceDefaultPassword;
                    camera.id = camera_server.id;
                    camera.operable = operable;
                    
                    // Save data to sqlite
                    NSError *error = nil;
                    if (![camera.managedObjectContext save:&error]) {
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                        abort();
#endif
                    } else {
                        NSLog(@"Saved to sqlite.");
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NeedReloadDataBase"];
                        [SHTutkHttp registerDevice:camera];
                    }
                } else {
                    NSLog(@"Create a camera");
                    self.savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:[CoreDataHandler sharedCoreDataHander].managedObjectContext];
                    self.savedCamera.cameraUid = cameraUid; //@"3AW1YKX6HWYG2M8X111A";
                    self.savedCamera.cameraName = cameraName;
                    self.savedCamera.devicePassword = kDeviceDefaultPassword;
                    self.savedCamera.id = camera_server.id;
                    self.savedCamera.operable = operable;
                    
                    NSDate *date = [NSDate date];
                    NSTimeInterval sec = [date timeIntervalSinceNow];
                    NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];

                    NSDateFormatter *df = [[NSDateFormatter alloc] init];
                    [df setDateFormat:@"yyyyMMdd HHmmss"];
                    self.savedCamera.createTime = [df stringFromDate:currentDate];
                    NSLog(@"Create time is %@",self.savedCamera.createTime);
                    
                    // Save data to sqlite
                    NSError *error = nil;
                    if (![self.savedCamera.managedObjectContext save:&error]) {
                        /*
                         Replace this implementation with code to handle the error appropriately.
                         
                         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                         */
                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                        abort();
#endif
                    } else {
                        NSLog(@"Saved to sqlite.");
                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NeedReloadDataBase"];
                        [SHTutkHttp registerDevice:self.savedCamera];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
                    [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:^{
                        if (isExist) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kCameraAlreadyExistNotification object:cameraName];
                        }
                    }];
                });
            } else {
#if 0
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                });
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    Error *error = result;
                    SHLogError(SHLogTagAPP, @"bindCmaera is failed, error: %@", error.error_description);
                    
                    if (error.error_code == 50034) {
                        self.progressHUD.detailsLabelText = @"Device have been bind by other accounts.";
                        [self.progressHUD showProgressHUDNotice:@"Bind device failed" showTime:2.0];
                    } else {
                        [self.progressHUD showProgressHUDNotice:error.error_description showTime:2.0];
                    }
                });
#else
                Error *error = result;
                SHLogError(SHLogTagAPP, @"bindCmaera is failed, error: %@", error.error_description);
                
                [self bindDeviceFailedHandler:error];
#endif
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

- (void)bindDeviceFailedHandler:(Error *)error {
    NSString *title = @"Bind device failed";
    NSString *message = error.error_description;
    
    if (error.error_code == 50034) {
        message = @"Device have been bind by other accounts.";
    }
    
    [self showFailedAlertViewWithTitle:title message:message];
}

- (void)showFailedAlertViewWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
