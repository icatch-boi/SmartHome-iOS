// SHAccountSettingSwitchCell.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
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
 
 // Created by zj on 2019/4/15 3:34 PM.
    

#import "SHAccountSettingSwitchCell.h"
#import "SHAccountSettingItem.h"
#import "SHNetworkManagerHeader.h"

@interface SHAccountSettingSwitchCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISwitch *switchButton;

@property (nonatomic, weak) MBProgressHUD *progressHUD;

@end

@implementation SHAccountSettingSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupGUI];
}

- (void)setupGUI {
    [self.switchButton setOn:NO];
}

- (void)setItem:(SHAccountSettingItem *)item {
    [super setItem:item];
    
    _titleLabel.text = NSLocalizedString(item.title, nil);
    
    [self initSwitchStatus];
}

- (IBAction)switchClick:(id)sender {
    if ([self.item.title isEqualToString:@"kBackgroundWakeup"]) {
        [self backgroundWakeupHandle];
    }
}

- (void)initSwitchStatus {
    if ([self.item.title isEqualToString:@"kBackgroundWakeup"]) {
        NSDictionary *info = [SHNetworkManager sharedNetworkManager].userAccount.userExtensionsInfo;
        if (info == nil) {
            return;
        }
        
        if (![info.allKeys containsObject:@"bgWakeup"]) {
            return;
        }
        
        [self.switchButton setOn:[info[@"bgWakeup"] intValue]];
    }
}

- (void)backgroundWakeupHandle {
    if (self.switchButton.isOn) {
        [self showBackgroundWakeupAlertView];
    } else {
        [self updateBackgroundWakeupStatus];
    }
}

- (void)showBackgroundWakeupAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kEnableBackgroundWakeupDescription", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.switchButton setOn:NO];
        });
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself updateBackgroundWakeupStatus];
    }]];

    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] presentViewController:alertVC animated:YES completion:nil];
}

- (void)updateBackgroundWakeupStatus {
    NSDictionary *info = @{
                           @"bgWakeup": @(self.switchButton.isOn),
                           };
    
    WEAK_SELF(self);
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kSettingup", nil)];
    [[SHNetworkManager sharedNetworkManager] setUserExtensionsInfo:info completion:^(BOOL isSuccess, id  _Nullable result) {
        dispatch_async(dispatch_get_main_queue(), ^{
            STRONG_SELF(self);
            
            if (isSuccess == NO) {
                [self.switchButton setOn:!self.switchButton.isOn];
                
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kChangeBackgroundWakeupStatusFailed", nil) showTime:2.0];
            } else {
                [self.progressHUD hideProgressHUD:YES];
            }
        });
    }];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:[ZJSlidingDrawerViewController sharedSlidingDrawerVC].view];
    }
    
    return _progressHUD;
}

@end
