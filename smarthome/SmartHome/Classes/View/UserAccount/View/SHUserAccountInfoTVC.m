//
//  SHUserAccountInfoTVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHUserAccountInfoTVC.h"
#import "SHNetworkManagerHeader.h"
#import "SHMessagesListTVC.h"
#import <Photos/Photos.h>
#import "ZJSlidingDrawerViewController.h"

@interface SHUserAccountInfoTVC () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatorImgView;
@property (weak, nonatomic) IBOutlet UILabel *nickNameLabel;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UILabel *modifyPWDLabel;

@property (nonatomic, weak) MBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL enableFaceRecognition;

@end

@implementation SHUserAccountInfoTVC

+ (instancetype)userAccountInfoTVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kUserAccountStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"SHUserAccountInfoTVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
    _enableFaceRecognition = [SHCameraManager sharedCameraManger].smarthomeCams.count > 0;
}

- (void)setupGUI {
//    [_logoutButton setCornerWithRadius:_logoutButton.bounds.size.height * 0.5 masksToBounds:NO];
    UIImage *placeholderImage = [UIImage imageNamed:@"portrait-1"];
    _avatorImgView.image = [placeholderImage ic_avatarImageWithSize:placeholderImage.size backColor:[UIColor whiteColor] lineColor:[UIColor lightGrayColor] lineWidth:1.0];
    _nickNameLabel.text = SHNetworkManager.sharedNetworkManager.userAccount.screen_name;
    
    [_logoutButton setTitle:NSLocalizedString(@"kLogout", nil) forState:UIControlStateNormal];
    [_logoutButton setTitle:NSLocalizedString(@"kLogout", nil) forState:UIControlStateHighlighted];
    _modifyPWDLabel.text = NSLocalizedString(@"kModifyPassword", nil);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)logoutClick:(id)sender {
#if 0
    [[SHNetworkManager sharedNetworkManager] logout];
    [self.navigationController popViewControllerAnimated:YES];
#endif
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:/*@"Alert"*/NSLocalizedString(@"Tips", nil) message:/*@"Here is a message where we an put absolutely anything we want."*/NSLocalizedString(@"kLogoutAlertInfo", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:/*@"Cancel"*/NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertC addAction:[UIAlertAction actionWithTitle:/*@"Log out"*/NSLocalizedString(@"kLogout", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself logout];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)logout {
//    [self.navigationController popViewControllerAnimated:YES];
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] logoutWithCompation:^(BOOL isSuccess, id  _Nonnull result) {
        if (isSuccess) {
            [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] popViewController];
            [[ZJSlidingDrawerViewController sharedSlidingDrawerVC] closeLeftMenu];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserShouldLoginNotification object:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
            });
        } else {
            weakself.progressHUD.detailsLabelText = NSLocalizedString(@"kLogoutAgain", nil); //@"please try again later";
            [weakself.progressHUD showProgressHUDNotice:/*@"Sign out failed"*/NSLocalizedString(@"kLogoutFailed", nil) showTime:1.5];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {

    switch (indexPath.row) {
        case 1:
            [self enableFaceRecognitionHandlerWithCell:cell];
            break;
            
        default:
            break;
    }
}

- (void)enableFaceRecognitionHandlerWithCell:(UITableViewCell *)cell {
    uint32_t textC;
    
    if (self.enableFaceRecognition) {
        textC = kTextColor;
        
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        textC = 0x8E8E8E;
        
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    UILabel *titleLab = cell.contentView.subviews.firstObject;
    titleLab.textColor = [UIColor ic_colorWithHex:textC];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 1) {
        [self showAlertWithTitle:NSLocalizedString(@"Tips", nil) message:@"使用 '生物识别' 功能务必确保账户下添加有相机，否则此功能不能被使用。"];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {    
    return 50.0;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"go2MessagesListTVCID"]) {
        SHMessagesListTVC *vc = segue.destinationViewController;
        vc.managedObjectContext = _managedObjectContext;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
//            [self readImageFromAlbum];
            [self modifyPassword];
            break;
            
        case 1:
            self.enableFaceRecognition ? [self enterFaceRecognition] : void();
            break;
            
        case 2:
            [self modifyPassword];
            break;
            
        default:
            break;
    }
}

- (void)enterFaceRecognition {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kFaceRecognitionStoryboardName bundle:nil];
    UINavigationController *nav = [sb instantiateInitialViewController];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)modifyPassword {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:/*@"Change password"*/NSLocalizedString(@"kModifyPassword", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    __block UITextField *oldPWDField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.placeholder = NSLocalizedString(@"kOldPassword", nil); //@"Old password";
        textField.secureTextEntry = YES;
        
        oldPWDField = textField;
    }];
    
    __block UITextField *newPWDField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.placeholder = NSLocalizedString(@"kNewPassword", nil); //@"New password";
        textField.secureTextEntry = YES;

        newPWDField = textField;
    }];
    
    __block UITextField *surePWDField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.placeholder = NSLocalizedString(@"kSurePassword", nil); //@"Sure password";
        textField.secureTextEntry = YES;

        surePWDField = textField;
    }];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"Cancel"*/NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"OK"*/NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([weakself checkPassword:oldPWDField.text newPassword:newPWDField.text surePassword:surePWDField.text]) {
            [weakself changePasswordWithOldPassword:oldPWDField.text newPassword:newPWDField.text];
        }
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (BOOL)checkPassword:(NSString *)password newPassword:(NSString *)newPassword surePassword:(NSString *)surePassword {
    if (![newPassword isEqualToString:surePassword]) {
        [self showAlertWithTitle:/*@"Change password failed"*/NSLocalizedString(@"kModifyPasswordFailed", nil) message:/*@"Sorry, the new password and confirming password disagree!"*/NSLocalizedString(@"kNewPasswordDisagree", nil)];
        return NO;
    }
    
    if ([password isEqualToString:newPassword]) {
        [self showAlertWithTitle:/*@"Change password failed"*/NSLocalizedString(@"kModifyPasswordFailed", nil) message:/*@"Sorry, the old password and new password agree!"*/NSLocalizedString(@"kOldAndNewPasswordAgree", nil)];
        return NO;
    }

    return YES;
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"OK"*/NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] changePasswordWithOldPassword:oldPassword newPassword:newPassword completion:^(BOOL isSuccess, id  _Nonnull result) {
        SHLogInfo(SHLogTagAPP, @"changePasswordWithOldPassword is success: %d", isSuccess);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *message = NSLocalizedString(@"kModifyPasswordSuccess", nil); //@"Change password success.";

            if (!isSuccess) {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"changePasswordWithOldPassword is failed, error: %@", error.error_description);
                
                weakself.progressHUD.detailsLabelText = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]; //error.error_description;

                message = NSLocalizedString(@"kModifyPasswordFailed", nil); //@"Change password failed";
            }
            
            [weakself.progressHUD showProgressHUDNotice:message showTime:2.0];
        });
    }];
}

#pragma mark - ReadImage
- (void)readImageFromAlbum {
    // 1、 获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device) {
        // 判断授权状态
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
        if (status == PHAuthorizationStatusNotDetermined) { // 用户还没有做出选择
            // 弹框请求用户授权
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) { // 用户第一次同意了访问相册权限
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                        [SHTool configureAppThemeWithController:imagePicker];
                        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //（选择类型）表示仅仅从相册中选取照片
                        imagePicker.delegate = self;
                        [self presentViewController:imagePicker animated:YES completion:nil];
                    });
                } else { // 用户第一次拒绝了访问相机权限
                    
                }
            }];
            
        } else if (status == PHAuthorizationStatusAuthorized) { // 用户允许当前应用访问相册
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            [SHTool configureAppThemeWithController:imagePicker];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary; //（选择类型）表示仅仅从相册中选取照片
            imagePicker.delegate = self;
            [self presentViewController:imagePicker animated:YES completion:nil];
            
        } else if (status == PHAuthorizationStatusDenied) { // 用户拒绝当前应用访问相册
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:/*@"⚠️ 警告"*/[NSString stringWithFormat:@"⚠️ %@", NSLocalizedString(@"Warning", nil)] message:/*[NSString stringWithFormat:@"请去-> [设置 - 隐私 - 照片 - %@] 打开访问开关", APP_NAME]*/NSLocalizedString(@"kCameraAccessWarningInfo", nil) preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:/*@"确定"*/NSLocalizedString(@"Sure", nil) style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        } else if (status == PHAuthorizationStatusRestricted) {
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:/*@"温馨提示"*/NSLocalizedString(@"Tips", nil) message:/*@"由于系统原因, 无法访问相册"*/NSLocalizedString(@"kNotAccessSystemAlbum", nil) preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:/*@"确定"*/NSLocalizedString(@"Sure", nil) style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        }
    }
}

#pragma mark - - - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    [self setUserAvatorWithImage:image];
    
    [self dismissViewControllerAnimated:YES completion:^{
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setUserAvatorWithImage:(UIImage *)image {
    double imageSize = image.size.width * image.size.height * 4 / 1024;
    SHLogInfo(SHLogTagAPP, @"imageSize: %f", imageSize);
    UIImage *compressionImage = [self compressionImage:image];
    SHLogInfo(SHLogTagAPP, @"compression after image: %@", compressionImage);

    WEAK_SELF(self);
    NSData *avatorData = UIImageJPEGRepresentation(image, 0.5);
    [[SHNetworkManager sharedNetworkManager] setUserAvatorWithData:avatorData completion:^(BOOL isSuccess, id  _Nonnull result) {
        SHLogInfo(SHLogTagAPP, @"setUserAvatorWithData is success: %d", isSuccess);
        
        if (isSuccess) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakself.avatorImgView.image = [compressionImage ic_avatarImageWithSize:compressionImage.size backColor:[UIColor whiteColor] lineColor:[UIColor lightGrayColor] lineWidth:1.0];
            });
        } else {
            Error *error = result;
            SHLogError(SHLogTagAPP, @"setUserAvatorWithData failed, error: %@", error.error_description);
            weakself.progressHUD.detailsLabelText = [SHNetworkRequestErrorDes errorDescriptionWithCode:error.error_code]; //error.error_description;
            [weakself.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", nil) showTime:2.0];
        }
    }];
}

- (UIImage *)compressionImage:(UIImage *)image {
    CGFloat width = image.size.width;
    CGFloat height = image.size.height;
    CGFloat imageSize = width * height * 4 / 1024;
    
    while (imageSize > 60) {
        width /= 2;
        height /= 2;
        imageSize = width * height * 4 / 1024;
    }
    
    CGSize size = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
    }
    
    return _progressHUD;
}


/*
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}
*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
