//
//  SHFindCameraVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/13.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHFindCameraVC.h"
#import "SHCameraInfoViewController.h"
#import "SHFindIndicator.h"
#import "SHAPModeViewController.h"
#import "SimpleLink.h"
#import "SimpleLinkErrorID.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

static int const totalFindTime = 60;

@interface SHFindCameraVC ()

@property (weak, nonatomic) IBOutlet UIView *tipsView;
@property (weak, nonatomic) IBOutlet SHFindIndicator *findView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *connectTipsLab1;
@property (weak, nonatomic) IBOutlet UILabel *connectTipsLab2;
@property (weak, nonatomic) IBOutlet UILabel *tipsTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;


@property (assign, nonatomic) CGFloat findTimes;
@property (nonatomic) NSTimer *findTimer;
@property (nonatomic) NSTimeInterval findInterval;

@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic) icatchtek::simplelink::SimpleLink *link;
@property (nonatomic, strong) NSString *cameraUid;
@property (nonatomic) UIAlertController *alertVC;

@end

@implementation SHFindCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
    
    [_findView setBackgroundColor:self.view.backgroundColor];
    [_findView setStrokeColor:[UIColor cyanColor]];
    [_findView loadIndicator];
    [self findTimer];
    _findInterval = 100.0 / totalFindTime;
    [self setupLink];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self releaseTimer];
    _link->cancel();
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupGUI {
    [_tipsView setCornerWithRadius:10.0];
    [_tipsView setBorderWidth:1.0 borderColor:[UIColor darkGrayColor]];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = [NSString stringWithFormat:@"%@（60s）", NSLocalizedString(@"kAreLookingForin", @"")];
    _tipsTitleLabel.text = NSLocalizedString(@"Tips", nil);
    _connectTipsLab1.text = NSLocalizedString(@"kConnectTipsInfo1", nil);
    _connectTipsLab2.text = NSLocalizedString(@"kConnectTipsInfo2", nil);
    [_exitButton setTitle:NSLocalizedString(@"kExit", nil) forState:UIControlStateNormal];
    [_exitButton setTitle:NSLocalizedString(@"kExit", nil) forState:UIControlStateHighlighted];
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2CameraInfoVCSegue"]) {
        SHCameraInfoViewController *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.cameraUid = _cameraUid;
        vc.devicePWD = _devicePWD;
    } else if ([segue.identifier isEqualToString:@"go2APModeSegue"]) {
        SHAPModeViewController *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
        vc.devicePWD = _devicePWD;
    }
}

- (NSTimer *)findTimer {
    if (_findTimer == nil) {
        _findTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateViewStatus) userInfo:nil repeats:YES];
    }
    
    return _findTimer;
}

- (void)releaseTimer {
    [_findTimer invalidate];
    _findTimer = nil;
}

- (void)updateViewStatus
{
    _findTimes++;
    int temp = _findInterval * _findTimes;
    
    [_findView updateWithTotalBytes:100 downloadedBytes:temp];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _titleLabel.text = [NSString stringWithFormat:@"%@（%02ds）", NSLocalizedString(@"kAreLookingForin", @""), (int)(totalFindTime - _findTimes)];
    });
    
    if (temp >= 100) {
        [self releaseTimer];

//        [_alertVC dismissViewControllerAnimated:YES completion:nil];
//        [self performSegueWithIdentifier:@"go2APModeSegue" sender:nil];
        [self showEnterAPModelAlertView];
        
        return;
    }
//    else if (temp > 50) {
//        [self releaseTimer];
//
//        [self performSegueWithIdentifier:@"go2CameraInfoVCSegue" sender:nil];
//
//        return;
//    }
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
    retValue = _link->init(icatchtek::simplelink::LINKTYPE_SMARTLINK, totalFindTime, 5, (char *)cryptoKey.UTF8String, 16, flag);
    if (retValue != SIMPLELINK_ERR_OK) {
        [self updateError:NSLocalizedString(@"kAPModeConnectFiled", @"") error:retValue];
        return;
    }
    
    retValue = _link->setContent(ssid.UTF8String, pwd.UTF8String, _devicePWD.UTF8String, [self getIPAddress].UTF8String, "0.0.0.0", "00:00:00:00:00:00");
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
        
//        if (!retVal) {
//            NSString *message = [NSString stringWithFormat:@"%s", content.c_str()];
//
//            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
//            NSLog(@"----> dict: %@", dict);
//
//            if (dict) {
//                _cameraUid = dict[@"id"];
//            }
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];

            if (!retVal) {
                _cameraUid = [NSString stringWithFormat:@"%s", content.c_str()];
                [self releaseTimer];
                [self performSegueWithIdentifier:@"go2CameraInfoVCSegue" sender:nil];
            } else {
                [self releaseTimer];

                if (_findInterval * _findTimes < 100) {
                    //                [self.progressHUD showProgressHUDNotice:@"link failed !" showTime:2.0];
                    [self showEnterAPModelAlertView];
                }
            }
        });
    });
}

- (void)showEnterAPModelAlertView {
    _alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"⚠️") message:NSLocalizedString(@"kSmartlinkFailed", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    [_alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [_alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"go2APModeSegue" sender:nil];
    }]];
    
    [self presentViewController:_alertVC animated:YES completion:nil];
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

#pragma mark - show warning dialog
- (void)showWarningAlertDialog:(NSString*)warningMessage {
    if([warningMessage isEqualToString:@""] == YES) {
        NSLog(@"showWarningAlertDialog :: No Message To Show");
        return;
    }
    
    @autoreleasepool {
        dispatch_async(dispatch_get_main_queue(), ^() {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"⚠️")
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

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUD;
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

//获取WIFIIP的方法
- (NSString *)getIPAddress
{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    NSLog(@"address:%@",address);
    return address;
}

@end
