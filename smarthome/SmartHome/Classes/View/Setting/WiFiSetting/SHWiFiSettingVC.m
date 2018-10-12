// SHWiFiSettingVC.m

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
 
 // Created by zj on 2018/4/9 下午4:49.
    

#import "SHWiFiSettingVC.h"
#import "SHWiFiSettingCell.h"

static NSString * const kWiFiSSIDReuseID = @"wifiSSIDReuseID";
static NSString * const kPasswordReuseID = @"passwordReuseID";

@interface SHWiFiSettingVC () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;

@property (weak, nonatomic) UITextField *ssidTextField;
@property (weak, nonatomic) UITextField *pwdTextField;
@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation SHWiFiSettingVC

+ (instancetype)wifiSettingVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"WiFiSettingVCSBID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [_submitButton setCornerWithRadius:_submitButton.bounds.size.height * 0.25];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)swipeToExit:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)submitAction:(id)sender {
    [_ssidTextField resignFirstResponder];
    [_pwdTextField resignFirstResponder];
    
    __block NSString *ssid = _ssidTextField.text;
    __block NSString *password = _pwdTextField.text;
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        if ([self checkSSID:ssid password:password]) {
            return;
        }
        
        SHCameraObject *obj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid];
        BOOL ret = [obj.sdk setupWiFiWithSSID:ssid password:password];
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSString *notice = @"setup success.";
            if (ret) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self swipeToExit:nil];
                });
            } else {
                notice = @"setup failed.";
            }
            
            [self.progressHUD showProgressHUDNotice:notice showTime:2.0];
        });
    });
}

- (BOOL)checkSSID:(NSString *)ssid password:(NSString *)passwprd {
    BOOL error = NO;
    NSString * errorMessage = nil;
    
    if( ![self isValidSSID:ssid] ) {
        error = YES;
        errorMessage = @"Incorrect SSID (<12 characters)";
    }
    
    if(![self isValidPassword:passwprd]) {
        error = YES;
        errorMessage = @"Invalid Password (at least 8 numeric characters)";
    }
    
    if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:errorMessage showTime:2.0];
        });
    }
    
    return error;
}

- (BOOL)isValidSSID:(NSString *)ssid{
    SHLogInfo(SHLogTagAPP, @"check wifissid: %@", ssid);
    
    if( ssid == nil)
        return NO;
    if( ssid.length < 1 /*|| ssid.length > 12*/)
        return NO;
    return [self isAlphaNumeric:ssid];
}

- (BOOL)isAlphaNumeric:(NSString *)string
{
    //NSCharacterSet *unwantedCharacters = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    //return ([self rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound);
    NSError * error;
    NSString *modifiedString = nil;
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[01234567890abcdefghijklmnopqrstuvwxyz_\\-]" options:NSRegularExpressionCaseInsensitive error:&error];
    modifiedString = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@""];
    
    SHLogInfo(SHLogTagAPP, @"modifyString:%@", modifiedString);
    if( modifiedString == nil || [modifiedString isEqualToString:@""])
        return YES;
    else
        return NO;
}

- (BOOL)isValidPassword:(NSString *)password
{
    SHLogInfo(SHLogTagAPP, @"check wifipassword: %@",password);
    
    if( password == nil)
        return NO;
    if( password.length < 8 /*|| password.length > 10*/)
        return NO;
    return [self isAlphaNumeric:password];
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
    
    SHWiFiSettingCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self getSubViewWithCell:cell indexPath:indexPath];
    
    return cell;
}

- (void)getSubViewWithCell:(SHWiFiSettingCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        _ssidTextField = cell.wifiSSIDTextField;
        [_ssidTextField becomeFirstResponder];
    } else if (indexPath.row == 1) {
        _pwdTextField = cell.passwordTextField;
    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.navigationController.view.window];
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
