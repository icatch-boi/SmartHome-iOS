// SHAccountSettingViewModelItem.m

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
 
 // Created by zj on 2019/4/16 4:55 PM.
    

#import "SHAccountSettingViewModelItem.h"
#import "SHAccountSettingItem.h"
#import "SHAccountSettingAvatarCell.h"
#import "SHAccountSettingCommonCell.h"
#import "SHAccountSettingSwitchCell.h"
#import "SHNetworkManagerHeader.h"

#pragma mark - SHAccountSettingViewModelBaseItem
@implementation SHAccountSettingViewModelBaseItem

@synthesize items;
@synthesize rowCount;
@synthesize sectionTitle;
@synthesize rowHeight;

+ (instancetype)baseItemWithAccountSettingItems:(NSArray<SHAccountSettingItem *> *)items {
    id <SHAccountSettingViewModelItem> viewModelItem = [self new];
    
    viewModelItem.items = items;
    
    return viewModelItem;
}

- (NSInteger)rowCount {
    return self.items.count;
}

- (CGFloat)rowHeight {
    return kCommonRowHeight;
}

- (UITableViewCell *)cellWithTableView:(UITableView *)tableView forIndexPath:(NSIndexPath *)indexPath {
    SHAccountSettingItem *item = items[indexPath.row];
    
    NSString *identifier = item.identifier;
    if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingAvatarCell class])]) {
        SHAccountSettingAvatarCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;
        
        return cell;
    } else if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingCommonCell class])]) {
        SHAccountSettingCommonCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;
        
        return cell;
    } else if ([identifier isEqualToString:NSStringFromClass([SHAccountSettingSwitchCell class])]) {
        SHAccountSettingSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier forIndexPath:indexPath];
        
        cell.item = item;
        
        return cell;
    }
    
    return [UITableViewCell new];
}

@end

#pragma mark - SHAccountSettingViewModelProfileItem
@implementation SHAccountSettingViewModelProfileItem

- (CGFloat)rowHeight {
    return kProfileRowHeight;
}

@end

#pragma mark - SHAccountSettingViewModelServiceItem
@implementation SHAccountSettingViewModelServiceItem


@end

#pragma mark - SHAccountSettingViewModelSettingItem
@interface SHAccountSettingViewModelSettingItem ()

@property (nonatomic, weak) MBProgressHUD *progressHUD;

@end

@implementation SHAccountSettingViewModelSettingItem

- (void)modifyAccountPasswordHandle {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kModifyPassword", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UITextField *oldPWDField = [self addTextFieldWithAlertController:alertVC placeholder:NSLocalizedString(@"kOldPassword", nil)];
    
    UITextField *newPWDField = [self addTextFieldWithAlertController:alertVC placeholder:NSLocalizedString(@"kNewPassword", nil)];
    
    UITextField *surePWDField = [self addTextFieldWithAlertController:alertVC placeholder:NSLocalizedString(@"kSurePassword", nil)];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([weakself checkPassword:oldPWDField.text newPassword:newPWDField.text surePassword:surePWDField.text]) {
            [weakself changePasswordWithOldPassword:oldPWDField.text newPassword:newPWDField.text];
        }
    }]];
    
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] presentViewController:alertVC animated:YES completion:nil];
}

- (UITextField *)addTextFieldWithAlertController:(UIAlertController *)alertVC placeholder:(NSString *)placeholder {
    __block UITextField *textF = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.placeholder = placeholder;
        textField.secureTextEntry = YES;
        
        textF = textField;
    }];
    
    return textF;
}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] changePasswordWithOldPassword:oldPassword newPassword:newPassword completion:^(BOOL isSuccess, id  _Nonnull result) {
        SHLogInfo(SHLogTagAPP, @"changePasswordWithOldPassword is success: %d", isSuccess);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = NSLocalizedString(@"kModifyPasswordSuccess", nil);
            
            if (!isSuccess) {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"changePasswordWithOldPassword is failed, error: %@", error.error_description);
                
                weakself.progressHUD.detailsLabelText = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code];
                
                message = NSLocalizedString(@"kModifyPasswordFailed", nil);
            }
            
            [weakself.progressHUD showProgressHUDNotice:message showTime:2.0];
        });
    }];
}

- (BOOL)checkPassword:(NSString *)password newPassword:(NSString *)newPassword surePassword:(NSString *)surePassword {
    if (![SHTool isValidPassword:password] || ![SHTool isValidPassword:newPassword] || ![SHTool isValidPassword:surePassword]) {
        [self showAlertWithTitle:NSLocalizedString(@"kModifyPasswordFailed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"kAccountPasswordDes", nil), kPasswordMinLength, kPasswordMaxLength]];
        return NO;
    }
    
    if ([password isEqualToString:newPassword]) {
        [self showAlertWithTitle:NSLocalizedString(@"kModifyPasswordFailed", nil) message:NSLocalizedString(@"kOldAndNewPasswordAgree", nil)];
        return NO;
    }
    
    if (![newPassword isEqualToString:surePassword]) {
        [self showAlertWithTitle:NSLocalizedString(@"kModifyPasswordFailed", nil) message:NSLocalizedString(@"kNewPasswordDisagree", nil)];
        return NO;
    }
    
    return YES;
}

#pragma mark - Display AlertView
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:[ZJSlidingDrawerViewController sharedSlidingDrawerVC].view];
    }
    
    return _progressHUD;
}

@end
