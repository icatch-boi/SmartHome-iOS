//
//  SHCameraInfoViewController.m
//  SmartHome
//
//  Created by ZJ on 2017/12/12.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCameraInfoViewController.h"
#import "SimpleLink.h"
#import "SimpleLinkErrorID.h"
#import "SHNetworkManagerHeader.h"

static int const apmodeTimeout = 30;
static CGFloat const kConstraintConstant_CN = 50;
static CGFloat const kConstraintConstant_EN = 30;
static CGFloat const kTextFieldFontSize_CN = 14;
static CGFloat const kTextFieldFontSize_EN = 12;

@interface SHCameraInfoViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *cameraUidLabel;
@property (weak, nonatomic) IBOutlet UITextField *cameraNameTF;
@property (weak, nonatomic) IBOutlet UITextField *passwordTF;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UILabel *pwdLabel;
@property (weak, nonatomic) IBOutlet UILabel *apmodelConnectLab;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceNameLab;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;
@property (weak, nonatomic) IBOutlet UILabel *apModeConnectFinishLab;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewYConstant;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *deviceNameCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *devicePasswordCons;

@property (nonatomic, strong) SHCamera *savedCamera;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic) icatchtek::simplelink::SimpleLink *link;

@end

@implementation SHCameraInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cameraUidLabel.hidden = YES;
    self.passwordTF.hidden = _devicePWD ? YES : NO;
    self.pwdLabel.hidden = _devicePWD ? YES : NO;
    _imageViewYConstant.constant = _devicePWD ? 40 : 80;
    
    if (_pwdLabel.hidden) {
        [_pwdLabel removeFromSuperview];
    }
    if (_passwordTF.hidden) {
        [_passwordTF removeFromSuperview];
    }
    
    if (_wifiPWD || _wifiSSID) {
        [self setupLink];
    } else {
        if (self.cameraUid != nil && self.cameraUid.length > 0) {
//            [self initParameter];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[self.cameraUid dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
#if 0
#if DEBUG
            dict ? [self shareHander:dict] : [self initParameter];
#else
            dict ? [self shareHander:dict] : [self showQRCodeInvalidAlertView];
#endif
#else
            dict ? [self shareHander:dict] : [self showQRCodeInvalidAlertView];
#endif
        }
    }
    
    self.cameraNameTF.delegate = self;
    self.passwordTF.delegate = self;
    
    [self.cameraNameTF addTarget:self action:@selector(onUidChanged) forControlEvents:UIControlEventEditingChanged];
    
    [self setupGUI];
}

- (void)showQRCodeInvalidAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kQRCodeInvalidTipsInfo", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self.navigationController popViewControllerAnimated:YES];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)initParameter {
    int parseResult = 0;
    NSString *token = [[SHQRManager sharedQRManager] getTokenFromQRString:self.cameraUid parseResult:&parseResult];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (token == nil || uid == nil) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[self tipsInfoFromParseResult:parseResult] preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                //                    [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                [self.navigationController popViewControllerAnimated:YES];
            });
        }]];
        [self presentViewController:alertVC animated:YES completion:nil];
        
        return;
    }
    
    //        self.cameraUidLabel.text = [NSString stringWithFormat:@"设备UID: %@", uid];
    self.cameraNameTF.text = [uid substringToIndex:5];
    //        self.passwordTF.text = [uid substringToIndex:5];
    self.passwordTF.text = _devicePWD;
    
    _addButton.enabled = YES;
    [self updateButtonBorderColor];
}

- (NSString *)tipsInfoFromParseResult:(int)result {
    NSString *message = nil;
    
    switch (result) {
        case ICH_QR_VALID:
            message = NSLocalizedString(@"kQRCodeInvalidTipsInfo", nil);
            break;
            
        case ICH_QR_DIE:
            message = NSLocalizedString(@"kQRCodeFailureTipsInfo", nil);
            break;
            
        case ICH_QR_USEABORT:
            message = NSLocalizedString(@"kCameraFailureTipsInfo", nil);
            break;
            
        default:
            message = NSLocalizedString(@"kQRCodeReadException", @"");
            break;
    }
    
    return [message stringByAppendingFormat:@"\n\n 二维码内容为: %@", self.cameraUid];
}

- (void)setupGUI {
    [_addButton setCornerWithRadius:_addButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_addButton setBorderWidth:1.0 borderColor:_addButton.titleLabel.textColor];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = NSLocalizedString(@"kFindCmaeraResultInfo", nil);
    _deviceNameLab.text = [NSString stringWithFormat:@"%@:", NSLocalizedString(@"kDeviceName", nil)];
    _pwdLabel.text = NSLocalizedString(@"kDevicePassword", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_addButton title:NSLocalizedString(@"kAddCamera", nil)];
    _apModeConnectFinishLab.text = NSLocalizedString(@"kAPModeConnectFinishTips", nil);
    _apmodelConnectLab.text = NSLocalizedString(@"kAPModeConnectTipsInfo", nil);
    _passwordTF.placeholder = NSLocalizedString(@"kInputDevicePassword", nil);

    [self updateTextFieldPropertyByAppLanguage];
}

- (void)updateTextFieldPropertyByAppLanguage {
    // 获取当前设备语言
    NSArray *appLanguages = [[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"];
    NSString *languageName = [appLanguages objectAtIndex:0];
    
    if ([languageName isEqualToString:@"zh-Hans-CN"] || [languageName isEqualToString:@"zh-Hant-CN"]) {
        _deviceNameCons.constant = kConstraintConstant_CN;
        _devicePasswordCons.constant = kConstraintConstant_CN;
        _passwordTF.font = [UIFont systemFontOfSize:kTextFieldFontSize_CN];
    } else {
        _deviceNameCons.constant = kConstraintConstant_EN;
        _devicePasswordCons.constant = kConstraintConstant_EN;
        _passwordTF.font = [UIFont systemFontOfSize:kTextFieldFontSize_EN];
    }
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)updateButtonBorderColor {
    [_addButton setBorderWidth:1.0 borderColor:_addButton.titleLabel.textColor];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (_wifiPWD || _wifiSSID) {
        _link->cancel();
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)addCameraClick:(UIButton *)sender {
    __block NSRange cameraPwdRange;
    __block NSRange cameraNameRange;
    
    [self.progressHUD showProgressHUDWithMessage:@"Setup camera's Info..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            cameraPwdRange = [_passwordTF.text rangeOfString:@"[A-Za-z0-9_(?![，。？：；’‘！”“、]]{1,32}" options:NSRegularExpressionSearch];
            cameraNameRange = [_cameraNameTF.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
        });
        
        if (cameraPwdRange.location == NSNotFound || cameraNameRange.location == NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
//                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
//                                                                message:@"Invalid information."
//                                                               delegate:nil
//                                                      cancelButtonTitle:NSLocalizedString(@"Sure", @"")
//                                                      otherButtonTitles:nil, nil];
//                [alert show];
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kInvalidParameterSettings", @"") preferredStyle:UIAlertControllerStyleAlert];
                [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertC animated:YES completion:nil];
            });
        } else {
            __block NSString *cameraName = nil;
            __block NSString *devicePassword = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                cameraName = _cameraNameTF.text;
                devicePassword = _devicePWD ? _devicePWD : _passwordTF.text;
            });
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
            [fetchRequest setEntity:entity];
            
            int parseResult = 0;
            NSString *token = [[SHQRManager sharedQRManager] getTokenFromQRString:_cameraUid parseResult:&parseResult];
            NSString *uidToken = [[SHQRManager sharedQRManager] getUIDToken:token];
            NSString *uid = [[SHQRManager sharedQRManager] getUID:token];

            if (token == nil || uidToken == nil || uid == nil) {
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[self tipsInfoFromParseResult:parseResult] preferredStyle:UIAlertControllerStyleAlert];
                [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressHUD hideProgressHUD:YES];
//                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:alertVC animated:YES completion:nil];
                });
                
                return;
            }
            
#if 1
            NSString *cameraUid = nil;
#if USE_ENCRYP
            cameraUid = token;
#else
            cameraUid = uid;
#endif
            [[SHNetworkManager sharedNetworkManager] bindCameraWithCameraUid:cameraUid name:cameraName password:devicePassword completion:^(BOOL isSuccess, id result) {
                NSLog(@"bindCmaera is success: %d", isSuccess);
                
                if (isSuccess) {
                    Camera *camera_server = result;
                    
#if USE_ENCRYP
                    NSPredicate *predicate = [NSPredicate
                                              predicateWithFormat:@"cameraUidToken = %@", uidToken];
#else
                    NSPredicate *predicate = [NSPredicate
                                              predicateWithFormat:@"cameraUid = %@", uid];
#endif
                    [fetchRequest setPredicate:predicate];
                    
                    BOOL isExist = NO;
                    NSError *error = nil;
                    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    if (!error && fetchedObjects && fetchedObjects.count>0) {
                        NSLog(@"Already have one camera: %@", uid);
                        isExist = YES;
                        
                        SHCamera *camera = fetchedObjects.firstObject;
                        camera.cameraName = cameraName;
#if USE_ENCRYP
                        camera.cameraToken = token;
                        camera.cameraUidToken = uidToken;
#else
                        camera.cameraUid = camera_server.uid;
#endif
                        camera.devicePassword = devicePassword;
                        camera.id = camera_server.id;
                        camera.operable = camera_server.operable;
                        
                        // Save data to sqlite
                        NSError *error = nil;
                        if (![camera.managedObjectContext save:&error]) {
                            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                            abort();
#endif
                        } else {
                            NSLog(@"Saved to sqlite.");
                        }
                    } else {
                        NSLog(@"Create a camera");
                        self.savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
//                        self.savedCamera.cameraUid = _cameraUid; //@"3AW1YKX6HWYG2M8X111A";
                        self.savedCamera.cameraName = cameraName;
#if USE_ENCRYP
                        self.savedCamera.cameraToken = token;
                        self.savedCamera.cameraUidToken = uidToken;
#else
                        self.savedCamera.cameraUid = uid;
#endif
                        self.savedCamera.devicePassword = devicePassword;
                        self.savedCamera.id = camera_server.id;
                        self.savedCamera.operable = camera_server.operable;
                        
                        NSDate *date = [NSDate date];
                        NSTimeInterval sec = [date timeIntervalSinceNow];
                        NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
//                        NSLog(@"Create time is %@",currentDate);
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
                                [[NSNotificationCenter defaultCenter] postNotificationName:kCameraAlreadyExistNotification object:_cameraNameTF.text];
                            }
                        }];
                    });
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                    });
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        Error *error = result;
                        
                        [self.progressHUD showProgressHUDNotice:error.error_description showTime:2.0];
                    });
                }
            }];
#else
            NSPredicate *predicate = [NSPredicate
                                      predicateWithFormat:@"cameraUidToken = %@", uidToken];
            [fetchRequest setPredicate:predicate];
            
            BOOL isExist = NO;
            NSError *error = nil;
            NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (!error && fetchedObjects && fetchedObjects.count>0) {
                NSLog(@"Already have one camera: %@", uid);
                isExist = YES;
                
                SHCamera *camera = fetchedObjects.firstObject;
                camera.cameraName = cameraName;
                camera.cameraToken = token;
                camera.cameraUidToken = uidToken;
                camera.devicePassword = devicePassword;
                
                // Save data to sqlite
                NSError *error = nil;
                if (![camera.managedObjectContext save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                    abort();
#endif
                } else {
                    NSLog(@"Saved to sqlite.");
                }
            } else {
                NSLog(@"Create a camera");
                self.savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
//                self.savedCamera.cameraUid = _cameraUid; //@"3AW1YKX6HWYG2M8X111A";
                self.savedCamera.cameraName = cameraName;
                self.savedCamera.cameraToken = token;
                self.savedCamera.cameraUidToken = uidToken;
                self.savedCamera.devicePassword = devicePassword;
                NSDate *date = [NSDate date];
                NSTimeInterval sec = [date timeIntervalSinceNow];
                NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
                //                NSLog(@"Create time is %@",currentDate);
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
                        [[NSNotificationCenter defaultCenter] postNotificationName:kCameraAlreadyExistNotification object:_cameraNameTF.text];
                    }
                }];
            });
#endif
        }
    });
}

#pragma mark - UITextFieldDelegate
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    //    NSRange cameraUidRange = [_cameraUidField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
    //    NSRange cameraNameRange = [_cameraNameField.text rangeOfString:@"[^\u4e00-\u9fa5]{1,32}" options:NSRegularExpressionSearch];
    //
    //    if (cameraUidRange.location == NSNotFound || cameraNameRange.location == NSNotFound) {
    //        _setupBtn.enabled = NO;
    //    } else {
    //        _setupBtn.enabled = YES;
    //    }
    
    _addButton.enabled = (_cameraUid && _cameraNameTF.text.length > 0);

    [textField resignFirstResponder];
    return YES;
}

- (void)onUidChanged {
    //convert to uppercase
//    if([self.cameraUid length] > 0){
//        NSString *upperUid = [self.cameraUid uppercaseStringWithLocale:[NSLocale currentLocale]];
//        self.cameraUidLabel.text = upperUid;
//    }
//    if([self.cameraUidField.text length] <= 5){
//        self.cameraNameField.text = self.cameraUidField.text;
//    }else{
//        self.cameraNameField.text = [self.cameraUidField.text substringToIndex:5];
//    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUD;
}

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
    retValue = _link->setContent(ssid.UTF8String, pwd.UTF8String, _devicePWD.UTF8String, "0.0.0.0", "0.0.0.0", "00:00:00:00:00:00", cameraUID.UTF8String);
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
                _apmodelConnectLab.text = NSLocalizedString(@"kConnectSuccess", nil);
                _cameraUid = [NSString stringWithFormat:@"%s", content.c_str()];
                [self initParameter];
            } else {
                _apmodelConnectLab.text = NSLocalizedString(@"ConnectError", @"");
                UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kAPModeConnectFiled", @"") preferredStyle:UIAlertControllerStyleAlert];
                
                [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
                }]];
                
                [self presentViewController:alertVC animated:YES completion:nil];
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

#pragma mark - ShareCameraHander
- (void)shareHander:(NSDictionary *)dict {
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
    NSString *message = accountName ? [NSString stringWithFormat:@"确定要订阅 %@ 分享给您的相机吗?", accountName] : @"确定要订阅新的相机吗?";

    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself subscribeCamera:dict];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
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
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.progressHUD.detailsLabelText = error.error_description;
                            [self.progressHUD showProgressHUDNotice:@"获取相机失败" showTime:2.0];
                            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                        });
                    }
                }];
            } else {
                Error *error = result;
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.progressHUD.detailsLabelText = error.error_description;
                    [self.progressHUD showProgressHUDNotice:@"订阅失败" showTime:2.0];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                    });
                });
            }
        }];
    });
}

- (void)showQRCodeExpireAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:@"分享二维码已过期." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)addCamera2LocalSqlite:(Camera *)camera_server {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
#if USE_ENCRYP
    int parseResult = 0;
    NSString *token = camera_server.uid;
    NSString *uidToken = [[SHQRManager sharedQRManager] getUIDToken:token];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (token == nil || uidToken == nil || uid == nil) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:[self tipsInfoFromParseResult:parseResult] preferredStyle:UIAlertControllerStyleAlert];
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                //                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                [self.navigationController popViewControllerAnimated:YES];
            });
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertVC animated:YES completion:nil];
        });
        
        return;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUidToken = %@", uidToken];
#else
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUid = %@", camera_server.uid];
#endif
    [fetchRequest setPredicate:predicate];
    
    BOOL isExist = NO;
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        NSLog(@"Already have one camera: %@", camera_server.uid);
        isExist = YES;
        
        SHCamera *camera = fetchedObjects.firstObject;
        camera.cameraName = camera_server.name;
#if USE_ENCRYP
        camera.cameraToken = token;
        camera.cameraUidToken = uidToken;
#else
        camera.cameraUid = camera_server.uid;
#endif
        camera.devicePassword = camera_server.devicepassword;
        camera.id = camera_server.id;
        camera.operable = camera_server.operable;
        
        // Save data to sqlite
        NSError *error = nil;
        if (![camera.managedObjectContext save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        } else {
            NSLog(@"Saved to sqlite.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            });
        }
    } else {
        NSLog(@"Create a camera");
        SHCamera *savedCamera = [NSEntityDescription insertNewObjectForEntityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
        savedCamera.cameraName = camera_server.name;
#if USE_ENCRYP
        savedCamera.cameraToken = token;
        savedCamera.cameraUidToken = uidToken;
#else
        savedCamera.cameraUid = camera_server.uid;
#endif
        savedCamera.devicePassword = camera_server.devicepassword;
        savedCamera.id = camera_server.id;
        savedCamera.operable = camera_server.operable;
        
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:@"订阅成功" showTime:2.0];
                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            });
        }
    }
}

@end
