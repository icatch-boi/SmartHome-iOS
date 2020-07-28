// SHAccountSettingTVC.m

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
 
 // Created by zj on 2019/4/15 3:07 PM.
    

#import "SHAccountSettingTVC.h"
#import "SHAccountSettingViewModel.h"
#import "SHNetworkManagerHeader.h"
#import "SHAccountSettingItem.h"
#import "SHMySharingTVC.h"

@interface SHAccountSettingTVC ()

@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (nonatomic, strong) SHAccountSettingViewModel *viewModel;
@property (nonatomic, weak) MBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL enableFaceRecognition;

@end

@implementation SHAccountSettingTVC

#pragma mark - Init
+ (instancetype)accountSettingTVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kUserAccountStoryboardName bundle:nil];
    
    return [sb instantiateViewControllerWithIdentifier:NSStringFromClass([self class])];
}

- (SHAccountSettingViewModel *)viewModel {
    if (_viewModel == nil) {
        _viewModel = [SHAccountSettingViewModel new];
    }
    
    return _viewModel;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setupGUI];
    _enableFaceRecognition = [SHCameraManager sharedCameraManger].smarthomeCams.count > 0 && [SHTool checkUserWhetherHaveOwnDevice];
}

- (void)setupGUI {
    self.tableView.dataSource = self.viewModel;
    self.tableView.delegate = self;
    
    [_logoutButton setTitle:NSLocalizedString(@"kLogout", nil) forState:UIControlStateNormal];
    [_logoutButton setTitle:NSLocalizedString(@"kLogout", nil) forState:UIControlStateHighlighted];
}

#pragma mark - Logout Handle
- (IBAction)logoutClick:(id)sender {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kLogoutAlertInfo", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kLogout", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself logoutHandle];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)logoutHandle {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] logoutWithCompation:^(BOOL isSuccess, id  _Nonnull result) {
        if (isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                
                [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] popViewController];
                [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] closeLeftMenu];
                [[NSNotificationCenter defaultCenter] postNotificationName:kUserShouldLoginNotification object:nil];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.progressHUD.detailsLabelText = NSLocalizedString(@"kLogoutAgain", nil);
                [weakself.progressHUD showProgressHUDNotice:NSLocalizedString(@"kLogoutFailed", nil) showTime:1.5];
            });
        }
    }];
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.viewModel.viewModelItems[indexPath.section] rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHAccountSettingItem *item = [self.viewModel.viewModelItems[indexPath.section] items][indexPath.row];
    if ([item.title isEqualToString:@"kBiometricsRecognition"] && self.enableFaceRecognition == NO) {
        return;
    }
    
    SEL method = NSSelectorFromString(item.methodName);
    if ([self respondsToSelector:method]) {
        [self performSelector:method withObject:indexPath afterDelay:0];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    SHAccountSettingItem *item = [self.viewModel.viewModelItems[indexPath.section] items][indexPath.row];
    if ([item.title isEqualToString:@"kBiometricsRecognition"]) {
        [self showAlertWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kBiometricsDescription", nil)];
    }
}

#pragma mark - Click Handle
- (void)modifyAccountPassword:(NSIndexPath *)indexPath {
    id <SHAccountSettingViewModelItem> item = self.viewModel.viewModelItems[indexPath.section];
    if ([item respondsToSelector:@selector(modifyAccountPasswordHandle)]) {
        [item performSelector:@selector(modifyAccountPasswordHandle)];
    }
}

- (void)enterFaceRecognition {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kFaceRecognitionStoryboardName bundle:nil];
    UINavigationController *nav = [sb instantiateInitialViewController];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)enterMySharing:(NSIndexPath *)indexPath {
    SHAccountSettingItem *item = [self.viewModel.viewModelItems[indexPath.section] items][indexPath.row];

    SHMySharingTVC *vc = [SHMySharingTVC mySharingTVC];
    vc.title = NSLocalizedString(item.title, nil);
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Display AlertView
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}

@end
