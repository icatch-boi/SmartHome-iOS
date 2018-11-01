// SH_XJ_SettingDetailTVC.m

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
 
 // Created by zj on 2018/4/8 上午11:18.

typedef NS_OPTIONS(NSUInteger, SHDetailSettingSectionType) {
    SHDetailSettingSectionTypeBasic,
    SHDetailSettingSectionTypeSDCard,
    SHDetailSettingSectionTypeAlert,
    SHDetailSettingSectionTypeAbout,
};

#import "SH_XJ_SettingDetailTVC.h"
#import "SHShareCamera.h"
#import "SHDetailTableViewController.h"
#import "SHSDKEventListener.hpp"
#import "SHNetworkManager.h"
#import "SHNetworkManager+SHCamera.h"

@interface SH_XJ_SettingDetailTVC ()

@property (nonatomic, strong) NSMutableArray *mainMenuTable;
@property (nonatomic, strong) NSMutableArray *mainMenuBasicTable;
@property (nonatomic, strong) NSMutableArray *mainMenuAlertTable;
@property (nonatomic, strong) NSMutableArray *mainMenuAboutTable;
@property (nonatomic, strong) NSMutableArray *mainMenuSDCardTable;

@property (nonatomic, strong) SHCameraObject *shCamObj;
@property (nonatomic, strong) SHControlCenter *ctrl;

@property (nonatomic, strong) SHPropertyQueryResult *curResult;
@property (nonatomic, strong) SHPropertyQueryResult *supResult;

@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property (nonatomic) SHObserver *SDCardObserver;
@property (nonatomic) int SDUseableSize;
@property (nonatomic) int    SDTotalSize;
@property (nonatomic) BOOL   sdCardExisted;

@end

@implementation SH_XJ_SettingDetailTVC

+ (instancetype)settingDetailTVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    return [sb instantiateViewControllerWithIdentifier:@"XJ_SettingDetailTVC"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    _SDUseableSize = 256;
    [self setupGUI];
    [self initParameter];
    [self initMenuTable];
    [self addSDCardObserver];
}

- (void)setupGUI {
//    self.title = @"Device Information";
}

- (void)initParameter {
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = self.shCamObj.controler;
//    self.shCamObj.cameraProperty.fwUpdate = [_ctrl.propCtrl compareFWVersion:self.shCamObj curResult:self.curResult];
}

- (void)initMenuTable {
//    if (!self.shCamObj.cameraProperty.fwUpdate && ![self.shCamObj.cameraProperty checkSupportPropertyExist]) {
//        [_ctrl.propCtrl.ssp readFromPath:self.shCamObj.camera.cameraUid.md5];
//    } else {
//        [_ctrl.propCtrl.ssp cleanCache];
//    }
    
    [self.mainMenuTable insertObject:self.mainMenuBasicTable atIndex:SHDetailSettingSectionTypeBasic];
    [self.mainMenuTable insertObject:self.mainMenuSDCardTable atIndex:SHDetailSettingSectionTypeSDCard];
    [self.mainMenuTable insertObject:self.mainMenuAlertTable atIndex:SHDetailSettingSectionTypeAlert];
    //[self.mainMenuTable insertObject:self.mainMenuAboutTable atIndex:SHDetailSettingSectionTypeAbout];
    
//    [self loadSettingData];
}

- (void)loadSettingData {
//    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"LOAD_SETTING_DATA", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self fillBasicTable];
        [self fillAlertTable];
        [self fillAboutTable];
        [self fillSDCardTable];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.progressHUD hideProgressHUD:YES];
        });
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoverFromDisconnection) name:kCameraNetworkConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
    
    [self loadSettingData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeSDCardObserver];
    if (self.shCamObj.cameraProperty.fwUpdate) {
        if ([_ctrl.propCtrl.ssp saveToPath:self.shCamObj.camera.cameraUid.md5]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSString *key = [NSString stringWithFormat:@"%@FWVersion:", self.shCamObj.camera.cameraUid];
            
            ICatchCameraVersion version = [_ctrl.propCtrl retrieveCameraVersionWithCamera:self.shCamObj curResult:self.curResult];
            NSString *curFirmwareVer = [NSString stringWithFormat:@"%s", version.getFirmwareVer().c_str()];
            
            [defaults setObject:curFirmwareVer forKey:key];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraNetworkConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSingleDownloadCompleteNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)swipeToExit:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - NotificationHandle
- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
    SHFile *file = tempDict[@"file"];
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"kFileDownloadCompleteTipsInfo", nil), tempDict[@"cameraName"], file.f.getFileName().c_str()];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.notificationView showGCDNoteWithMessage:msg andTime:kShowDownloadCompleteNoteTime withAcvity:NO];
    });
}

- (void)recoverFromDisconnection {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.mainMenuTable.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.mainMenuTable.count) {
        NSArray *tempArray = self.mainMenuTable[section];
        return [tempArray count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"detailSettingCellID" forIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor blackColor];
    
    if (indexPath.section == SHDetailSettingSectionTypeBasic) {
        if (indexPath.row) {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == SHDetailSettingSectionTypeAlert) {
        [cell.textLabel setTextColor:[UIColor redColor]];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SHDetailSettingSectionTypeAbout) {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.section == SHDetailSettingSectionTypeSDCard) {
        if(indexPath.row == 2) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
    
    // Configure the cell...
    if ([self validityCheckOfIndexPath:indexPath]) {
        SHSettingData *data = self.mainMenuTable[indexPath.section][indexPath.row];
        cell.textLabel.text = data.textLabel;
        cell.detailTextLabel.text = data.detailTextLabel;
    }
    
    return cell;
}

- (BOOL)validityCheckOfIndexPath:(NSIndexPath *)indexPath {
    BOOL valid = NO;
    
    if (indexPath.section < self.mainMenuTable.count) {
        NSArray *sectionArray = self.mainMenuTable[indexPath.section];
        if (indexPath.row < sectionArray.count) {
            valid = YES;
        }
    }
    
    if (valid == NO) {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kInvalidSettingData", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        WEAK_SELF(self);
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakself swipeToExit:nil];
        }]];
        
        [self presentViewController:alertC animated:YES completion:nil];
    }
    
    return valid;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case SHDetailSettingSectionTypeBasic:
            title = @"Info";
            break;
            
        case SHDetailSettingSectionTypeAlert:
            title = @"Alert";
            break;
            
        case SHDetailSettingSectionTypeSDCard:
            title = @"SD Card";
            
        default:
            break;
    }
    
    return title;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if ([self validityCheckOfIndexPath:indexPath]) {
        SHSettingData *data = self.mainMenuTable[indexPath.section][indexPath.row];
        
        SEL sel = NSSelectorFromString(data.methodName);
        if (sel && [self respondsToSelector:sel]) {
            id object = nil;
            
            if ([data.methodName hasSuffix:@":"]) {
                object = data;
            }
            
            [self performSelector:sel withObject:object afterDelay:0];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if ([self validityCheckOfIndexPath:indexPath]) {
        SHSettingData *data = self.mainMenuTable[indexPath.section][indexPath.row];
        
        SEL sel = NSSelectorFromString(data.methodName);
        if (sel && [self respondsToSelector:sel]) {
            id object = nil;
            
            if ([data.methodName hasSuffix:@":"]) {
                object = data;
            }
            
            [self performSelector:sel withObject:object afterDelay:0];
        }
    }
}

-(void)showAlertWithContent:(NSString *)message {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);

    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUD hideProgressHUD:YES];
            
        });
    }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertC animated:YES completion:nil];
    });
}

#pragma mark - Method
- (void)modifyCameraName {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"kModifyCameraName", @"") message:NSLocalizedString(@"kInputCameraName", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    __block UITextField *nameField = nil;
    [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = _shCamObj.camera.cameraName;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        
        nameField = textField;
    }];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"") style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        if ([nameField.text isEqualToString:@""] || [nameField.text isEqualToString:_shCamObj.camera.cameraName]) {
            return ;
        }
        
//        _shCamObj.camera.cameraName = nameField.text;
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#if 0
            // Save data to sqlite
            NSError *error = nil;

            if (![_shCamObj.camera.managedObjectContext save:&error]) {
                /*
                 Replace this implementation with code to handle the error appropriately.
                 
                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                 */
                SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            } else {
                SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                [self updateShareCameras];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf loadSettingData];
                });
            }
#endif
            __block NSString *newName = nil;
            dispatch_sync(dispatch_get_main_queue(), ^{
                newName = nameField.text;
            });
            
            if(_shCamObj.camera.operable == 1) {
                [[SHNetworkManager sharedNetworkManager] renameCameraByCameraID:_shCamObj.camera.id andNewName:newName completion:^(BOOL isSuccess, id  _Nonnull result) {
                    if(isSuccess) {
                        [self showAlertWithContent:@"修改名称成功!"];
                        
                        [_shCamObj.camera.managedObjectContext performBlockAndWait:^{
                            self.shCamObj.camera.cameraName = newName;
                            //                        (SHSettingData *)(self.mainMenuBasicTable[0]).detailTextLabel = self.shCamObj.camera.cameraName;
                            SHSettingData *nameData = (SHSettingData *)self.mainMenuBasicTable[0];
                            nameData.detailTextLabel = self.shCamObj.camera.cameraName;
                            NSError *error = nil;
                            
                            if (![_shCamObj.camera.managedObjectContext save:&error]) {
                                /*
                                 Replace this implementation with code to handle the error appropriately.
                                 
                                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                                 */
                                SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                                abort();
#endif
                            } else {
                                SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                                [self updateShareCameras];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [weakSelf loadSettingData];
                                });
                            }
                        }];
                    } else {
                        [self showAlertWithContent:@"修改名称失败!"];
                    }
                }];
            } else {
                [[SHNetworkManager sharedNetworkManager] fixedAliasByCameraID:_shCamObj.camera.id andAlias:newName completion:^(BOOL isSuccess, id  _Nonnull result) {
                    if(isSuccess) {
                        [self showAlertWithContent:@"修改名称成功!"];
                        
                        [_shCamObj.camera.managedObjectContext performBlockAndWait:^{
                            self.shCamObj.camera.cameraName = newName;
                            SHSettingData *nameData = (SHSettingData *)self.mainMenuBasicTable[0];
                            nameData.detailTextLabel = self.shCamObj.camera.cameraName;
                            NSError *error = nil;
                            
                            if (![_shCamObj.camera.managedObjectContext save:&error]) {
                                /*
                                 Replace this implementation with code to handle the error appropriately.
                                 
                                 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
                                 */
                                SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                                abort();
#endif
                            } else {
                                SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                                [self updateShareCameras];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [weakSelf loadSettingData];
                                });
                            }
                        }];
                    } else {
                        [self showAlertWithContent:@"修改名称失败!"];
                    }
                }];
            }
            
        });
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)updateShareCameras {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSData *data  = [userDefault objectForKey:kShareCameraInfoKey];
    NSArray *camerasArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    [camerasArray enumerateObjectsUsingBlock:^(SHShareCamera *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cameraUid isEqualToString:_shCamObj.camera.cameraUid]) {
            obj.cameraName = _shCamObj.camera.cameraName;
            *stop = YES;
        }
    }];
    
    NSData *saveData = [NSKeyedArchiver archivedDataWithRootObject:camerasArray];
    [userDefault setObject:saveData forKey:kShareCameraInfoKey];
}

- (void)alertViewWithTitle:(NSString *)title message:(NSString *)message cancelHandler:(void (^)())cancelHandler sureHandler:(void (^)())sureHandler {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (cancelHandler) {
            cancelHandler();
        }
    }]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        if (sureHandler) {
            sureHandler();
        }
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)cleanSpaceAction {
    WEAK_SELF(self);

    [self alertViewWithTitle:NSLocalizedString(@"ClearAppTemp", nil) message:[self calcDocumentDirectorySpaceSize] cancelHandler:nil sureHandler:^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [SHTool cleanUpDownloadDirectoryWithPath:_shCamObj.camera.cameraUid.md5];
            [weakself fillAlertTable];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD showProgressHUDCompleteMessage:NSLocalizedString(@"kCleanComplete", @"")];
                [weakself.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SHDetailSettingSectionTypeAlert]] withRowAnimation:UITableViewRowAnimationFade];
            });
        });
    }];
}

- (void)formatSDCardAction {
    WEAK_SELF(self);
    
    [self alertViewWithTitle:NSLocalizedString(@"SETTING_FORMAT_CONFIRM", nil) message:NSLocalizedString(@"SETTING_FORMAT_DESC", nil) cancelHandler:nil sureHandler:^{
        [weakself formatSDCardHandler];
    }];
}

- (void)formatSDCardHandler {
    if (![_ctrl.propCtrl checkSDExistWithCamera:_shCamObj curResult:_shCamObj.cameraProperty.sdCardResult]) {
       
        [self alertViewWithTitle:nil message:NSLocalizedString(@"NoCard", nil) cancelHandler:nil sureHandler:nil];
        
        return;
    }
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"SETTING_FORMATTING", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL formatOK = [_shCamObj.sdk formatSD];
        if (formatOK) {
            [_shCamObj.gallery cleanDateInfo];
            [_shCamObj.cameraProperty updateSDCardInfo:_shCamObj];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *text = formatOK?NSLocalizedString(@"SETTING_FORMAT_FINISH", nil):NSLocalizedString(@"SETTING_FORMAT_FAILED", nil);
            [self.progressHUD showProgressHUDCompleteMessage:text];
            
            [self loadSettingData];
        });
    });
}

- (void)factoryResetAction {
    WEAK_SELF(self);
    
    [self alertViewWithTitle:NSLocalizedString(@"SETTING_FACTORY_RESET", nil) message:NSLocalizedString(@"SETTING_FACTORY_RESET_DESC", nil) cancelHandler:nil sureHandler:^{
        STRONG_SELF(self);

        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"SETTING_FACTORY_RESETING", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            BOOL formatOK = [_ctrl.propCtrl factoryResetWithCamera:_shCamObj];
            if (formatOK) {
                [_shCamObj.cameraProperty cleanCurrentCameraAllProperty];
                
                self.curResult = nil;
                self.supResult = nil;
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *text = formatOK ? NSLocalizedString(@"SETTING_FACTORY_RESET_FINISH", nil):NSLocalizedString(@"SETTING_FACTORY_RESET_FAILED", nil);
                [self.progressHUD showProgressHUDCompleteMessage:text];
                
                [self loadSettingData];
            });
            
        });
    }];
}

- (void)enterDetailSettingView:(SHSettingData *)data {
    SHDetailTableViewController *vc = [SHDetailTableViewController detailTableViewController];
    vc.subMenuTable = data.detailData;
    vc.title = data.textLabel;
    
    [self.navigationController pushViewController:vc animated:YES];
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

#pragma mark - PrepareData
- (void)fillBasicTable {
    [self.mainMenuBasicTable removeAllObjects];
    
    [self fillCameraNameTable];
  
    [self fillVidRecDurationTable];
    [self fillSleepTimeTable];
    [self fillRecStatusTable];
    // [self fillFasterConnectionTable];
}

- (void)fillSDCardTable {
    [self.mainMenuSDCardTable removeAllObjects];
    [self fillMemorySizeTable];
    
    SHSettingData *myCard = [[SHSettingData alloc] init];
    myCard.textLabel = @"Usage";
     NSString *sizeStr = nil;
    if(_sdCardExisted) {
        int usedSize = (_SDTotalSize - _SDUseableSize);
        sizeStr = [DiskSpaceTool transformStringFromMBytes:usedSize];
        NSLog(@"total : %d, used : %d", _SDTotalSize, _SDUseableSize);
    } else {
       sizeStr = @"no card";
    }
     myCard.detailTextLabel = sizeStr;
    [self.mainMenuSDCardTable addObject:myCard];
    
    SHSettingData *formatSHCard = [[SHSettingData alloc] init];
    formatSHCard.textLabel = NSLocalizedString(@"SETTING_FORMAT", @"");
    formatSHCard.methodName = @"formatSDCardAction";
    
    if (formatSHCard) {
        [self.mainMenuSDCardTable addObject:formatSHCard];
    }
}

- (void)fillAlertTable {
    [self.mainMenuAlertTable removeAllObjects];
    
    SHSettingData *clearAppTempDirectory = [[SHSettingData alloc] init];
    clearAppTempDirectory.textLabel = NSLocalizedString(@"ClearAppTemp", @"");
    clearAppTempDirectory.detailTextLabel = [self calcDocumentDirectorySpaceSize];
    clearAppTempDirectory.methodName = @"cleanSpaceAction";
    
    if (clearAppTempDirectory) {
        [self.mainMenuAlertTable addObject:clearAppTempDirectory];
    }
    
   
    
    SHSettingData *factoryReset = [[SHSettingData alloc] init];
    factoryReset.textLabel = NSLocalizedString(@"SETTING_FACTORY_RESET", nil);
    factoryReset.methodName = @"factoryResetAction";
    
    if (factoryReset) {
        [self.mainMenuAlertTable addObject:factoryReset];
    }
}

- (void)fillAboutTable {
    [self.mainMenuAboutTable removeAllObjects];
    SHSettingData *aboutData = nil;
    if (_shCamObj.cameraProperty.aboutData == nil) {
        SHAbout *about = [SHAbout aboutWithCamera:_shCamObj];
        about.curResult = self.curResult;
        aboutData = [about prepareDataForAbout];
        aboutData.methodName = @"enterDetailSettingView:";
        _shCamObj.cameraProperty.aboutData = aboutData;
    } else {
        aboutData = _shCamObj.cameraProperty.aboutData;
    }
    
    if (aboutData) {
        [self.mainMenuAboutTable addObject:aboutData];
    }
}

#pragma mark - basic
- (void)fillCameraNameTable {
    SHSettingData *data = [[SHSettingData alloc] init];
    
    data.textLabel = NSLocalizedString(@"kCameraName", @"");
    data.detailTextLabel = _shCamObj.camera.cameraName;
    data.methodName = @"modifyCameraName";
    
    if (data) {
        [self.mainMenuBasicTable addObject:data];
    }
}

- (void)fillMemorySizeTable {
    SHSettingData *memorySizeData = nil;
    
    if (_shCamObj.cameraProperty.memorySizeData) {
        memorySizeData = _shCamObj.cameraProperty.memorySizeData;
        NSString *sizeStr = memorySizeData.detailTextLabel;
        if([sizeStr compare:@"no card"] != 0) {
            //查找空格位置
            NSRange range = [sizeStr rangeOfString:@" "];
            if(range.location != NSNotFound) {
                unsigned long position = range.location;
                //截取字符串
                NSString *subSizeStr = [sizeStr substringToIndex:position];
                self.SDTotalSize = [subSizeStr floatValue] * 1024;
                _sdCardExisted = YES;
            }
        }
    } else {
        int memorySize = [_shCamObj.controler.propCtrl retrieveSDCardFreeSpaceSizeWithCamera:_shCamObj curResult:nil];
        
        memorySizeData = [[SHSettingData alloc] init];
       // memorySizeData.textLabel = NSLocalizedString(@"SETTING_MEMORY_SIZE", nil);
        memorySizeData.textLabel = NSLocalizedString(@"SETTING_MEMORY_SIZE", nil);
        memorySizeData.detailTextLabel = memorySize == -1 ? @"no card" : [DiskSpaceTool transformStringFromMBytes:memorySize]; //[NSString stringWithFormat:@"%d MB", memorySize];
        if(memorySize == -1) {
             _sdCardExisted = NO;
        } else {
             _sdCardExisted = YES;
        }
         _SDTotalSize = memorySize;
        _shCamObj.cameraProperty.memorySizeData = memorySizeData;
    }
    
    if (memorySizeData) {
        [self.mainMenuSDCardTable addObject:memorySizeData];
    }
}

- (void)fillVidRecDurationTable {
    SHSettingData *vidRecDurationData = nil;
    
    if (_shCamObj.cameraProperty.vidRecDurationData) {
        vidRecDurationData = _shCamObj.cameraProperty.vidRecDurationData;
    } else {
        SHVidRecDuration *rd = [SHVidRecDuration vidRecDurationWithCamera:_shCamObj];
        rd.curResult = self.curResult;
        rd.rangeResult = self.supResult;
        
        vidRecDurationData = [rd prepareDataForVidRecDuration];
        _shCamObj.cameraProperty.vidRecDurationData = vidRecDurationData;
    }
    
    if (vidRecDurationData) {
        [self.mainMenuBasicTable addObject:vidRecDurationData];
    }
}

- (void)fillSleepTimeTable {
    SHSettingData *sleepTimeData = nil;
    
    if (_shCamObj.cameraProperty.sleepTimeData) {
        sleepTimeData = _shCamObj.cameraProperty.sleepTimeData;
    } else {
        SHSleepTime *st = [SHSleepTime sleepTimeWithCamera:_shCamObj];
        st.curResult = self.curResult;
        st.rangeResult = self.supResult;
        
        sleepTimeData = [st prepareDataForSleepTime];
        _shCamObj.cameraProperty.sleepTimeData = sleepTimeData;
    }
    
    if (sleepTimeData) {
        [self.mainMenuBasicTable addObject:sleepTimeData];
    }
}

- (void)fillRecStatusTable {
    SHSettingData *recStatusData = nil;
    
    if (_shCamObj.cameraProperty.recStatusData) {
        recStatusData = _shCamObj.cameraProperty.recStatusData;
    } else {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_VID_REC_STATUS];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int recStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        recStatusData = [[SHSettingData alloc] init];
        recStatusData.textLabel = NSLocalizedString(@"SETTING_REC_STATUS", nil);
//        recStatusData.detailLastItem = recStatus;
        recStatusData.detailTextLabel = recStatus ? @"On" : @"Off";
        
        _shCamObj.cameraProperty.recStatusData = recStatusData;
    }
    
    if (recStatusData) {
        [self.mainMenuBasicTable addObject:recStatusData];
    }
}

- (void)fillFasterConnectionTable {
    SHSettingData *fasterConnectionData = nil;
    
    if (_shCamObj.cameraProperty.fasterConnectionData) {
        fasterConnectionData = _shCamObj.cameraProperty.fasterConnectionData;
    } else {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_CAMERA_ULTRA_POWER_SAVING_MODE];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int fasterConStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        fasterConnectionData = [[SHSettingData alloc] init];
        fasterConnectionData.textLabel = NSLocalizedString(@"SETTING_ULTRA_POWER_SAVING_MODE", nil);
//        fasterConnectionData.detailLastItem = pushMsgStatus;
        fasterConnectionData.detailTextLabel = fasterConStatus ? @"On" : @"Off";
        
        _shCamObj.cameraProperty.fasterConnectionData = fasterConnectionData;
    }
    
    if (fasterConnectionData) {
        [self.mainMenuBasicTable addObject:fasterConnectionData];
    }
}

- (NSString *)calcDocumentDirectorySpaceSize
{
    long long numberOfBytes = 0;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *documentsDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *logFilePath = nil;
    for (NSString *fileName in  documentsDirectoryContents) {
        if (![fileName isEqualToString:@"SHCamera.sqlite"] && ![fileName isEqualToString:@"SHCamera.sqlite-shm"] && ![fileName isEqualToString:@"SHCamera.sqlite-wal"] && ![fileName isEqualToString:@"SmartHome-Medias"] && ![fileName hasSuffix:@".db"] && ![fileName hasSuffix:@".plist"]) {
            
            logFilePath = [documentsDirectory stringByAppendingPathComponent:fileName];
            numberOfBytes += [DiskSpaceTool num_folderSizeAtPath:logFilePath];
            SHLogInfo(SHLogTagAPP, @"=======> %@", [DiskSpaceTool humanReadableStringFromBytes:numberOfBytes]);
        }
    }
    
    numberOfBytes += [DiskSpaceTool num_folderSizeAtPath:NSTemporaryDirectory()];
    
    // calc local thumbnail cache size.
    NSString *databaseName = [_shCamObj.camera.cameraUid.md5 stringByAppendingString:@".db"];
    numberOfBytes += [DiskSpaceTool fileSizeAtPath:[SHTool databasePathWithName:databaseName]];
    
    return [DiskSpaceTool humanReadableStringFromBytes:numberOfBytes];
}

#pragma mark - init
- (NSMutableArray *)mainMenuTable {
    if (_mainMenuTable == nil) {
        _mainMenuTable = [NSMutableArray array];
    }
    
    return _mainMenuTable;
}

- (NSMutableArray *)mainMenuBasicTable {
    if (_mainMenuBasicTable == nil) {
        _mainMenuBasicTable = [NSMutableArray array];
    }
    
    return _mainMenuBasicTable;
}

- (NSMutableArray *)mainMenuAlertTable {
    if (_mainMenuAlertTable == nil) {
        _mainMenuAlertTable = [NSMutableArray array];
    }
    
    return _mainMenuAlertTable;
}

- (NSMutableArray *)mainMenuAboutTable {
    if (_mainMenuAboutTable == nil) {
        _mainMenuAboutTable = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _mainMenuAboutTable;
}

- (NSMutableArray *)mainMenuSDCardTable {
    if (_mainMenuSDCardTable == nil) {
        _mainMenuSDCardTable = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _mainMenuSDCardTable;
}
- (SHPropertyQueryResult *)curResult {
    if (!_curResult) {
        _curResult = [_ctrl.propCtrl retrieveSettingCurPropertyWithCamera:_shCamObj];
    }
    
    return _curResult;
}

//- (SHPropertyQueryResult *)supResult {
//    if (!_supResult) {
//        _supResult = [_ctrl.propCtrl retrieveSettingSupPropertyWithCamera:_shCamObj];
//    }
//    
//    return _supResult;
//}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.navigationController.view.window];
    }
    
    return _progressHUD;
}

#pragma mark - GCDiscreetNotificationView
- (GCDiscreetNotificationView *)notificationView {
    if (!_notificationView) {
        _notificationView = [[GCDiscreetNotificationView alloc] initWithText:nil
                                                                showActivity:NO
                                                          inPresentationMode:GCDiscreetNotificationViewPresentationModeTop
                                                                      inView:self.view];
    }
    return _notificationView;
}
#pragma mark - Video Bitrate Observer
- (void)addSDCardObserver {
    SHSDKEventListener *SDCardListener = new SHSDKEventListener(self, @selector(updateSDCardInfo:));
    self.SDCardObserver = [SHObserver cameraObserverWithListener:SDCardListener eventType:ICATCH_EVENT_SDCARD_INFO_CHANGED isCustomized:NO isGlobal:NO];
    [_shCamObj.sdk addObserver:self.SDCardObserver];
}

- (void)removeSDCardObserver {
    if (self.SDCardObserver) {
        [_shCamObj.sdk removeObserver:self.SDCardObserver];
        
        if (self.SDCardObserver.listener) {
            delete self.SDCardObserver.listener;
            self.SDCardObserver.listener = nullptr;
        }
        
        self.SDCardObserver = nil;
    }
}

- (void)updateSDCardInfo:(SHICatchEvent *)evt {
    switch (evt.eventID) {
        case ICATCH_EVENT_SDCARD_INFO_CHANGED:
            [self updateBitRateLabel:evt.doubleValue1];
            break;
            
        default:
            break;
    }
}

- (void)updateBitRateLabel:(CGFloat)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        //_bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", (int)value];
        _SDUseableSize = (int)value;
        [self.tableView reloadData];
    });
}

@end
