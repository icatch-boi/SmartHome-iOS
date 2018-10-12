//
//  SHSetupCameraPWDVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/22.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHSetupCameraPWDVC.h"
#import "SHTurnonCameraVC.h"
#import "JJCPayCodeTextField.h"
#import "SHCameraInfoViewController.h"

@interface SHSetupCameraPWDVC ()

@property (weak, nonatomic) IBOutlet UIButton *nextButton;
@property (nonatomic, strong) JJCPayCodeTextField *textField;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

@end

@implementation SHSetupCameraPWDVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
    [self setupCodeTextField];
}

- (void)setupGUI {
    [_nextButton setCornerWithRadius:_nextButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_nextButton setBorderWidth:1.0 borderColor:_nextButton.titleLabel.textColor];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = NSLocalizedString(@"kSetupDevicePassword", nil);
    _tipsLabel.text = NSLocalizedString(@"kPasswordProtectionTips", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_nextButton title:NSLocalizedString(@"kNext", nil)];
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)setupCodeTextField {
    CGFloat x = ([UIScreen mainScreen].bounds.size.width - 250) * 0.5;
    _textField = [[JJCPayCodeTextField alloc] initWithFrame:CGRectMake(x, 200, 250, 50) TextFieldType:JJCPayCodeTextFieldTypeWholeBorder];
    _textField.textFieldNum = 4;
    
    _textField.ciphertext = @"●";
    [self.view addSubview:_textField];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (IBAction)nextClick:(UIButton *)sender {
    if (![_textField.payCodeString isEqualToString:@""]) {
        if (sender.tag == 0) {
            [self performSegueWithIdentifier:@"go2TurnonCameraSegue" sender:nil];
        } else if (sender.tag == 1) {
            [self performSegueWithIdentifier:@"go2CameraInfoSegue" sender:nil];
        }
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kSetupDevicePassword", @"") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure",nil) style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2TurnonCameraSegue"]) {
        SHTurnonCameraVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
        vc.devicePWD = _textField.payCodeString;
    } else if ([segue.identifier isEqualToString:@"go2CameraInfoSegue"]) {
        SHCameraInfoViewController *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
        vc.devicePWD = _textField.payCodeString;
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
