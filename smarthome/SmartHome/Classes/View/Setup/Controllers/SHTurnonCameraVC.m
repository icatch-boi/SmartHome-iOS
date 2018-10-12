//
//  SHTurnonCameraVC.m
//  SmartHome
//
//  Created by ZJ on 2017/12/13.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHTurnonCameraVC.h"
#import "SHFindCameraVC.h"
#import "SHAPModeViewController.h"

@interface SHTurnonCameraVC ()

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *turnonTipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *exitButton;

@end

@implementation SHTurnonCameraVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setupGUI];
}

- (void)setupGUI {
    [_startButton setCornerWithRadius:_startButton.bounds.size.height * 0.5 masksToBounds:YES];
    [_startButton setBorderWidth:1.0 borderColor:_startButton.titleLabel.textColor];
    
    self.title = NSLocalizedString(@"kConnectionWizard", nil);
    _titleLabel.text = NSLocalizedString(@"kTurnonCamera", nil);
    _turnonTipsLabel.text = NSLocalizedString(@"kTurnonCmaeraTips", nil);
    [self setButtonTitle:_exitButton title:NSLocalizedString(@"kExit", nil)];
    [self setButtonTitle:_startButton title:NSLocalizedString(@"kRedLightFlashing", nil)];
}

- (void)setButtonTitle:(UIButton *)btn title:(NSString *)title {
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateHighlighted];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)exitAddClick:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddCameraExitNotification object:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2FindCameraSegue"]) {
        SHFindCameraVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
        vc.devicePWD = _devicePWD;
    } else if ([segue.identifier isEqualToString:@"go2APModeVCSegue"]) {
        SHAPModeViewController *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
        vc.directEnterAPMode = YES;
        vc.wifiSSID = _wifiSSID;
        vc.wifiPWD = _wifiPWD;
    }
}

@end
