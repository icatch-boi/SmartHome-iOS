//
//  SHMessagesListTVC.m
//  SmartHome
//
//  Created by ZJ on 2018/3/14.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHMessagesListTVC.h"
#import "SHNetworkManagerHeader.h"
#import "SHMessageCell.h"
#import "SHUserAccountCommon.h"

@interface SHMessagesListTVC ()

@property (nonatomic, strong) NSMutableArray *messagesMArray;
@property (nonatomic) MBProgressHUD *progressHUD;

@end

@implementation SHMessagesListTVC

+ (instancetype)messageListTVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kUserAccountStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"MessagesListTVCID"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self getMessages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messagesMArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"messageCellID" forIndexPath:indexPath];
    
    // Configure the cell...
    if (indexPath.row < _messagesMArray.count) {
        Message *message = _messagesMArray[indexPath.row];
        cell.message = message;
    }
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showInviteAlertAtIndexPath:indexPath];
}

- (void)showInviteAlertAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= _messagesMArray.count) {
        return;
    }
    
    Message *message = _messagesMArray[indexPath.row];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"您确定要接受朋友的邀请吗 ?" preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:@"残忍拒绝" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"残忍拒绝");
        [weakself clearMessageWithMessage:message completion:^(BOOL isSuccess) {
            if (isSuccess) {
                [weakself.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            }
        }];
    }]];
    [alertC addAction:[UIAlertAction actionWithTitle:@"接受邀请" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"接受邀请");
        [weakself subscribeCameraWithMessage:message];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)subscribeCameraWithMessage:(Message *)message {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    WEAK_SELF(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] subscribeCameraWithCameraID:message.deviceId cameraName:[[NSUserDefaults standardUserDefaults] objectForKey:kSubscribeCameraName] invitationCode:nil completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"subscribe camera is success: %d", isSuccess);
            
            if (isSuccess) {
                [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:message.deviceId completion:^(BOOL isSuccess, id  _Nonnull result) {
                    SHLogInfo(SHLogTagAPP, @"get camera is success: %d", isSuccess);

                    BOOL getCameraSuccess = isSuccess;
                    
                    [weakself clearMessageWithMessage:message completion:^(BOOL isSuccess) {
                        if (getCameraSuccess) {
                            [self addCamera2LocalSqlite:result];
                        } else {
                            Error *error = result;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.progressHUD.detailsLabelText = error.error_description;
                                [self.progressHUD showProgressHUDNotice:@"获取相机失败" showTime:2.0];
                            });
                            
                            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                                [self.navigationController popViewControllerAnimated:YES];
                            });
                        }
                    }];
                }];
            } else {
                [weakself clearMessageWithMessage:message completion:^(BOOL isSuccess) {
                    Error *error = result;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.progressHUD.detailsLabelText = error.error_description;
                        [self.progressHUD showProgressHUDNotice:@"订阅失败" showTime:2.0];
                    });
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }];
            }
        }];
    });
}

- (void)addCamera2LocalSqlite:(Camera *)camera_server {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"SHCamera" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
#if USE_ENCRYP
    NSString *token = camera_server.uid;
    NSString *uidToken = [[SHQRManager sharedQRManager] getUIDToken:token];
    NSString *uid = [[SHQRManager sharedQRManager] getUID:token];
    
    if (token == nil || uidToken == nil || uid == nil) {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:@"uid 解析失败" preferredStyle:UIAlertControllerStyleAlert];
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
                [self.navigationController popViewControllerAnimated:YES];
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
//                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self.navigationController.topViewController dismissViewControllerAnimated:YES completion:nil];
                [self.navigationController popViewControllerAnimated:YES];
            });
        }
    }
}

- (void)clearMessageWithMessage:(Message *)message completion:(void (^)(BOOL isSuccess))completion {
#if 0
    WEAK_SELF(self);
    
    [[SHNetworkManager sharedNetworkManager] clearMessageWithMessageIds:@[message.msgId] completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"clear Message is success: %d", isSuccess);

        if (isSuccess) {
            [weakself.messagesMArray removeObject:message];
        }
        
        if (completion) {
            completion(isSuccess);
        }
    }];
#endif
    completion(NO);
}

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

- (void)getMessages {
    self.progressHUD.detailsLabelText = nil;
    [self.progressHUD showProgressHUDWithMessage:nil];
    
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] getMessages:^(BOOL isSuccess, id  _Nonnull result) {
        SHLogInfo(SHLogTagAPP, @"get messages is success: %d", isSuccess);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isSuccess) {
                _messagesMArray = result;
                
                [_messagesMArray sortUsingComparator:^NSComparisonResult(Message* obj1, Message* obj2) {
                    NSTimeInterval ti1 = [SHUserAccountCommon timeIntervalString:obj1.time];
                    NSTimeInterval ti2 = [SHUserAccountCommon timeIntervalString:obj2.time];
                    return ti2 > ti1 ? NSOrderedDescending : NSOrderedAscending;
                }];
                [weakself.progressHUD hideProgressHUD:YES];
                [weakself.tableView reloadData];
            } else {
                Error *error = result;
                
                weakself.progressHUD.detailsLabelText = error.error_description;
                [weakself.progressHUD showProgressHUDNotice:@"获取消息失败" showTime:2.0];
            }
        });
    }];
}

#pragma mark - MBProgressHUD
- (MBProgressHUD *)progressHUD {
    if (_progressHUD == nil) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUD;
}

@end
