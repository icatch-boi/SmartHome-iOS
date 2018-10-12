//
//  SHShareOtherAccountVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/13.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareOtherAccountVC.h"
#import "SHNetworkManagerHeader.h"
#import "ShareCommonHeader.h"

@interface SHShareOtherAccountVC () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *otherAccountTextField;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;

@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation SHShareOtherAccountVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
}

- (void)setupGUI {
    _otherAccountTextField.delegate = self;
    [_shareButton setCornerWithRadius:_shareButton.bounds.size.height * 0.5 masksToBounds:NO];
    
    [_otherAccountTextField addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
    [_otherAccountTextField becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareClick:(id)sender {
    [_otherAccountTextField resignFirstResponder];
    __block NSRange accountRange;
    
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:@"正在分享..."];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            accountRange = [_otherAccountTextField.text rangeOfString:@"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}" options:NSRegularExpressionSearch];
        });
        
        if (accountRange.location == NSNotFound) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"输入的账户无效，请重新输入." preferredStyle:UIAlertControllerStyleAlert];
                [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alertC animated:YES completion:nil];
            });
        } else {
            __block NSString *account = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                account = _otherAccountTextField.text;
            });
            
            [[SHNetworkManager sharedNetworkManager] shareCameraWithCameraID:_camera.id toUser:account permission:0x00 duration:kShareDuration completion:^(BOOL isSuccess, id  _Nullable result) {
                SHLogInfo(SHLogTagAPP, @"share camera to user is success: %d", isSuccess);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *notice = @"分享成功.";
                    
                    if (isSuccess) {
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                    } else {
                        Error *error = result;
                        
                        self.progressHUD.detailsLabelText = error.error_description;
                        notice = @"分享失败";
                    }
                    
                    [self.progressHUD showProgressHUDNotice:notice showTime:1.0];
                });
            }];
        }
    });
}

- (void)textFieldTextChange:(UITextField *)textField {
    _shareButton.enabled = textField.text.length;
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
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
