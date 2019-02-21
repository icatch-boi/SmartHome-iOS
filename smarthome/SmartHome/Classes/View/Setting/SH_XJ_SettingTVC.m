// SH_XJ_SettingTVC.m

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
 
 // Created by zj on 2018/4/8 上午9:53.
    

#import "SH_XJ_SettingTVC.h"
#import "SHDeleteCameraCell.h"
#import "SH_XJ_SettingDetailTVC.h"
#import "SHMpbTVC.h"
#import "SHWiFiSettingVC.h"
#import "SHNetworkManagerHeader.h"
#import "SHPushTestNavController.h"
//#import "XJLocalAssetHelper.h"
#import "AppDelegate.h"

typedef NS_OPTIONS(NSUInteger, SHSettingSectionType) {
    SHSettingSectionTypeBasic,
    SHSettingSectionTypeDetail,
    SHSettingSectionTypeDeleteCamera,
};

static NSString * const kDeleteCameraCellID = @"DeleteCameraCellID";

@interface SH_XJ_SettingTVC ()

@property (nonatomic, strong) SHCameraObject *shCamObj;
@property (nonatomic, strong) SHControlCenter *ctrl;

@property (nonatomic, strong) SHPropertyQueryResult *curResult;
@property (nonatomic, strong) SHPropertyQueryResult *supResult;

@property (nonatomic, strong) NSMutableArray  *mainMenuTable;
@property (nonatomic, strong) NSMutableArray  *mainMenuBasicTable;
@property (nonatomic, strong) NSMutableArray  *mainMenuDetailTable;
@property (nonatomic, strong) NSMutableArray  *mainMenuDeleteCameraTable;


@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property (nonatomic, assign) BOOL hasLoad;

@end

@implementation SH_XJ_SettingTVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self setupGUI];
    [self initParameter];
//    [self loadSettingData];
}

- (void)initParameter {
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = self.shCamObj.controler;
//    if (_shCamObj.isConnect) {
//        self.shCamObj.cameraProperty.fwUpdate = [_ctrl.propCtrl compareFWVersion:self.shCamObj curResult:self.curResult];
//    }
}

- (void)setupGUI {
    self.title = NSLocalizedString(@"SETTING", @"");
    [self.tableView registerNib:[UINib nibWithNibName:@"DeleteCameraCell" bundle:nil] forCellReuseIdentifier:kDeleteCameraCellID];
}

- (void)loadSettingData {
    [self.mainMenuTable removeAllObjects];
    if (_shCamObj.isConnect) {
//        if (!self.shCamObj.cameraProperty.fwUpdate && ![self.shCamObj.cameraProperty checkSupportPropertyExist]) {
//            [_ctrl.propCtrl.ssp readFromPath:self.shCamObj.camera.cameraUid.md5];
//        } else {
//            [_ctrl.propCtrl.ssp cleanCache];
//        }
        
        [self.mainMenuTable insertObject:self.mainMenuBasicTable atIndex:SHSettingSectionTypeBasic];
        [self.mainMenuTable insertObject:self.mainMenuDetailTable atIndex:SHSettingSectionTypeDetail];
        [self.mainMenuTable insertObject:self.mainMenuDeleteCameraTable atIndex:SHSettingSectionTypeDeleteCamera];
    } else {
        [self.mainMenuTable insertObject:self.mainMenuDeleteCameraTable atIndex:0];
    }
    
    [self loadLocalData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoverFromDisconnection) name:kCameraNetworkConnectedNotification object:nil];
}

- (void)loadLocalData {
    if (_shCamObj.isConnect) {
        [self fillBasicTable];
    }
    [self fillDeleteCameraTable];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)loadRemoteData {
    if (_shCamObj.isConnect) {
        [self fillDetailTable];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_hasLoad && _shCamObj.isConnect) {
        return;
    }
    
    [self loadSettingData];
    _shCamObj.isConnect ? [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"LOAD_SETTING_DATA", nil)] : void();

    WEAK_SELF(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        if (_shCamObj.isConnect) {
//            [self fillBasicTable];
//            [self fillDetailTable];
//        }
//        [self fillDeleteCameraTable];
        STRONG_SELF(self);
        [self loadRemoteData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            [self.progressHUD hideProgressHUD:YES];
            _hasLoad = YES;
        });
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
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
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraNetworkConnectedNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    SHLogDebug(SHLogTagAPP, @"%@ - dealloc", self.class);
}

#pragma mark - NotificationHandle
- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
#if 0
    SHFile *file = tempDict[@"file"];
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"kFileDownloadCompleteTipsInfo", nil), tempDict[@"cameraName"], file.f.getFileName().c_str()];
#else
    NSString *msg = [SHTool createDownloadComplete:tempDict];
#endif
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.notificationView showGCDNoteWithMessage:msg andTime:kShowDownloadCompleteNoteTime withAcvity:NO];
    });
}

- (void)recoverFromDisconnection {
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = self.shCamObj.controler;
//    self.shCamObj.cameraProperty.fwUpdate = [_ctrl.propCtrl compareFWVersion:self.shCamObj curResult:self.curResult];
    
    [self.tableView reloadData];
}

- (IBAction)returnBackAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        SHLogInfo(SHLogTagAPP, @"QUIT -- SHSetting");
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.mainMenuTable.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.mainMenuTable.count) {
        NSArray *temp = self.mainMenuTable[section];
        return [temp count];
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuseIdentifier_Basic = @"settingCellBasicID";
    static NSString *reuseIdentifier_Detail = @"settingCellDetailID";
    
    UITableViewCell *cell = nil;
    
    if (_shCamObj.isConnect) {
        if (indexPath.section == SHSettingSectionTypeBasic) {
//            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Detail forIndexPath:indexPath];
            SHSettingData *data = _shCamObj.cameraProperty.memorySizeData;
            if (data != nil && data.detailLastItem == -1) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"settingCellRightDetailID"];
                if (cell == nil) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"settingCellRightDetailID"];
                }
                
                cell.detailTextLabel.text = data.detailTextLabel;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.userInteractionEnabled = NO;
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Detail forIndexPath:indexPath];
            }
            SHSettingData *basicData = self.mainMenuTable[indexPath.section][indexPath.row];
            cell.textLabel.text = basicData.textLabel;
 
        } else if (indexPath.section == SHSettingSectionTypeDetail) {
            
            if(indexPath.row == 0 || indexPath.row == 1) {
                cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Basic forIndexPath:indexPath];
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                
                SHSettingData *data = self.mainMenuDetailTable[indexPath.row];
                switchView.on = data.detailLastItem <= 0 ? NO : YES;
                
                [switchView addTarget:self action:@selector(updateSwitchStatus:) forControlEvents:UIControlEventValueChanged];
                
                cell.accessoryView = switchView;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Detail forIndexPath:indexPath];
            }
        } else if (indexPath.section == SHSettingSectionTypeDeleteCamera) {
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Detail forIndexPath:indexPath];
                cell.textLabel.text = self.mainMenuTable[indexPath.section][indexPath.row];
            } else {
                cell = [tableView dequeueReusableCellWithIdentifier:kDeleteCameraCellID forIndexPath:indexPath];
                
                if ([self validityCheckOfIndexPath:indexPath]) {
                    NSString *deleteCellTitle = self.mainMenuTable[indexPath.section][indexPath.row];
                    ((SHDeleteCameraCell *)cell).titleLabel.text = deleteCellTitle ? deleteCellTitle : /*@"Delete"*/NSLocalizedString(@"Delete", nil);
                }
            }
        }
        
        // Configure the cell...
        if ([self validityCheckOfIndexPath:indexPath] && indexPath.section != SHSettingSectionTypeDeleteCamera && indexPath.section != SHSettingSectionTypeBasic) {
            SHSettingData *data = self.mainMenuTable[indexPath.section][indexPath.row];
            cell.textLabel.text = data.textLabel;
            cell.detailTextLabel.text = data.detailTextLabel;
        }
    } else {
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier_Detail forIndexPath:indexPath];
            cell.textLabel.text = self.mainMenuTable[indexPath.section][indexPath.row];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:kDeleteCameraCellID forIndexPath:indexPath];
            
            if ([self validityCheckOfIndexPath:indexPath]) {
                NSString *deleteCellTitle = self.mainMenuTable[indexPath.section][indexPath.row];
                ((SHDeleteCameraCell *)cell).titleLabel.text = deleteCellTitle ? deleteCellTitle : /*@"Delete"*/NSLocalizedString(@"Delete", nil);
            }
        }
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
            [weakself returnBackAction:nil];
        }]];
        
        [self presentViewController:alertC animated:YES completion:nil];
    }
    
    return valid;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = nil;
    switch (section) {
        case SHSettingSectionTypeBasic:
            //title = NSLocalizedString(@"SETTING", nil);
            break;
            
        default:
            break;
    }
    
    return title;
}

- (void)changeCameraPropertyValue:(int)propertyID newValue:(int)newValue preSwitch:(UISwitch *)sender finished:(void (^)(BOOL success))finished {
#if 0
//    [self.progressHUD showProgressHUDWithMessage:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:propertyID];
        
        BOOL ret = [itemData changeRangeItemValueWithPropertyID:0 andNewValue:newValue];
        
        SHRangeItemData *recStatusItemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_VID_REC_STATUS];
        BOOL recRet = [recStatusItemData changeRangeItemValueWithPropertyID:0 andNewValue:newValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressHUD hideProgressHUD:YES];
            
            if (!ret || recRet == false) {
                sender.on = !newValue;
                sender.selected = YES;
                
//                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", @"") showTime:2.0];
                [self showOperationFailedAlertViewWithMessage:NSLocalizedString(@"STREAM_SET_ERROR", nil)];
            }
        });
    });
#else
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL retVal = NO;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            SHSettingProperty *currentPro = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
            
            [currentPro addProperty:TRANS_PROP_DET_PUSH_MSG_STATUS withIntValue:newValue];
            [currentPro addProperty:TRANS_PROP_DET_VID_REC_STATUS withIntValue:newValue];
            [currentPro addProperty:TRANS_PROP_DET_PIR_STATUS withIntValue:newValue];

            retVal = [currentPro submit];
        });
        
        SHLogInfo(SHLogTagAPP, @"change DET Property, ret: %d", retVal);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (retVal == NO) {
                sender.on = !newValue;
                sender.selected = YES;
                
                [self showOperationFailedAlertViewWithMessage:NSLocalizedString(@"STREAM_SET_ERROR", nil)];
            }
            
            if (finished) {
                finished(retVal);
            }
        });
    });
#endif
}

- (void)changeCameraPropertyWithPropertyID:(list<int>)propertyIDs newValue:(int)newValue sender:(UISwitch *)sender finished:(void (^)(BOOL success))finished {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block BOOL retVal = NO;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            SHSettingProperty *currentPro = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
            
            list<int>::const_iterator iter = propertyIDs.begin();
            for (; iter != propertyIDs.end(); iter++) {
                [currentPro addProperty:*iter withIntValue:newValue];
            }
            
            retVal = [currentPro submit];
        });
        
        SHLogInfo(SHLogTagAPP, @"Change Camera Property, ret: %d", retVal);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (retVal == NO) {
                sender.on = !newValue;
                sender.selected = YES;
                
                [self showOperationFailedAlertViewWithMessage:NSLocalizedString(@"STREAM_SET_ERROR", nil)];
            }
            
            if (finished) {
                finished(retVal);
            }
        });
    });
}

- (void)showOperationFailedAlertViewWithMessage:(NSString *)message {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)updateSwitchStatus:(UISwitch *)sender {
    if (sender.selected) {
        sender.selected = NO;
        return;
    }
    
    UITableViewCell *cell = (UITableViewCell *)sender.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    BOOL value = sender.isOn;
    
    switch (indexPath.section) {
        case SHSettingSectionTypeDetail:
            if (indexPath.row == 0) {
                [self changePushMsgStatusHandler:sender value:value];
            } else if (indexPath.row == 1) {
                [self changeTamperAlarmHandler:sender value:value];
            } else if (indexPath.row == 2) {

            }
            break;
            
        default:
            break;
    }
}

- (void)changePushMsgStatusHandler:(id)sender value:(BOOL)value {
    [self changeCameraPropertyValue:TRANS_PROP_DET_PUSH_MSG_STATUS newValue:value preSwitch:sender finished:^(BOOL success) {
        if (success) {
            _shCamObj.cameraProperty.pushMsgStatusData.detailLastItem = value;
            
            _shCamObj.cameraProperty.recStatusData.detailLastItem = value;
            _shCamObj.cameraProperty.recStatusData.detailTextLabel = value ? NSLocalizedString(@"SETTING_ON", nil) : NSLocalizedString(@"SETTING_OFF", nil); //@"On" : @"Off";
        }
    }];
}

- (void)changeTamperAlarmHandler:(id)sender value:(BOOL)value {
    list<int> propertyIDs = list<int>();
    propertyIDs.push_back(TRANS_PROP_TAMPER_ALARM);
    
    [self changeCameraPropertyWithPropertyID:propertyIDs newValue:value sender:sender finished:^(BOOL success) {
        if (success) {
            _shCamObj.cameraProperty.tamperalarmData.detailLastItem = value;
        }
    }];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!_shCamObj.isConnect) {
        if (indexPath.row == 0) {
            [self enterPustTestView];
        } else {
            [self showDeleteCameraAlertWithIndexPath:indexPath];
        }
        return;
    }
    
    switch (indexPath.section) {
        case SHSettingSectionTypeBasic:
        case SHSettingSectionTypeDetail:
            if ([self validityCheckOfIndexPath:indexPath] && indexPath.section != SHSettingSectionTypeDeleteCamera) {
                SHSettingData *data = self.mainMenuTable[indexPath.section][indexPath.row];
                SEL sel = NSSelectorFromString(data.methodName);
                if (sel && [self respondsToSelector:sel]) {
                    id object = nil;
                    if ([data.methodName hasSuffix:@":"]) {
                        object = data.textLabel;
                    }
                    
                    [self performSelector:sel withObject:object afterDelay:0];
                }
            }
            break;
            
        case SHSettingSectionTypeDeleteCamera:
            if (indexPath.row == 0) {
                [self enterPustTestView];
            } else {
                [self showDeleteCameraAlertWithIndexPath:indexPath];
            }
            break;
            
        default:
            break;
    }
}

#pragma mark - Method
- (void)enterAlbum {
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:kAlbumStoryboardName bundle:nil];
        UINavigationController *nav = [sb instantiateViewControllerWithIdentifier:@"AlbumStoryboardID"];
        
        nav.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor blackColor]};
        SHMpbTVC *vc = (SHMpbTVC *)nav.topViewController;
        vc.cameraUid = _shCamObj.camera.cameraUid;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self presentViewController:nav animated:YES completion:nil];
        });
    });
}

- (void)enterWiFiSetting:(NSString *)title {
    SHWiFiSettingVC *vc = [SHWiFiSettingVC wifiSettingVC];
    vc.title = title;
    vc.cameraUid = _cameraUid;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)enterDeviceInfo:(NSString *)title {
    SH_XJ_SettingDetailTVC *vc = [SH_XJ_SettingDetailTVC settingDetailTVC];
    vc.cameraUid = _cameraUid;
    vc.title = title;
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)enterPustTestView {
    SHPushTestNavController *nav = [SHPushTestNavController pushTestNavController];
    nav.title = _shCamObj.camera.cameraUid;
    [SHTool configureAppThemeWithController:nav];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        app.isFullScreenPV = YES;
        
        [self presentViewController:nav animated:YES completion:nil];
    });
}

#pragma mark - DeleteCamera
- (void)showDeleteCameraAlertWithIndexPath:(NSIndexPath *)indexPath {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:NSLocalizedString(@"Are you sure you want to remove this record", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        STRONG_SELF(self);
        
        [self deleteCameraWithCompletion:^{
            if ([self.delegate respondsToSelector:@selector(goHome)]) {
                [self.delegate goHome];
            }

            [self returnBackAction:nil];
        }];
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)deleteCameraWithCompletion:(void (^)())completion {
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#ifdef USE_SYNC_REQUEST_PUSH
        if (![SHTutkHttp unregisterDevice:_shCamObj.camera.cameraUid]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self showDeleteCameraFailedInfo];
            });
            return;
        }
        
#if 1
        if (_shCamObj.camera.operable == 1) {
            [self unbindCameraWithCompletion:completion];
        } else {
            [self unsubscribeCameraWithCompletion:completion];
        }
#else
        NSString *message = NSLocalizedString(@"Deleted", nil);
//        NSString *path = _shCamObj.camera.cameraUid.md5;
        if ([[CoreDataHandler sharedCoreDataHander] deleteCamera:_shCamObj.camera]) {
            _shCamObj.cameraProperty.fwUpdate = NO;
            if (_shCamObj.isConnect) {
                [_shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
            }
            //清除相机的push msg信息及缓存的视频缩略图
            MessageCenter *msgCenter = [MessageCenter MessageCenterWithName:_shCamObj.camera.cameraUid andMsgDelegate:nil];
            [msgCenter clearAllMessage];
            
//            [SHTool removeMediaDirectoryWithPath:path];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (completion) {
                    completion();
                }
            });
        } else {
            message = NSLocalizedString(@"DeleteError", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:message showTime:2.0];
        });
#endif
#else
        WEAK_SELF(self);
        [SHTutkHttp unregisterDevice:_shCamObj.camera.cameraUid completionHandler:^(BOOL isSuccess) {
            if (isSuccess == NO) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    [weakself showDeleteCameraFailedInfo];
                });
            } else {
                if (_shCamObj.camera.operable == 1) {
                    [weakself unbindCameraWithCompletion:completion];
                } else {
                    [weakself unsubscribeCameraWithCompletion:completion];
                }
            }
        }];
#endif
    });
}

- (void)showDeleteCameraFailedInfo {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kUnregisterDeviceFailed", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)deleteCameraDetailWithCompletion:(void (^)())completion {
    NSString *message = NSLocalizedString(@"Deleted", nil);
    
//    NSString *cameraUid = _shCamObj.camera.cameraUid;
    if ([[CoreDataHandler sharedCoreDataHander] deleteCamera:_shCamObj.camera]) {
        _shCamObj.cameraProperty.fwUpdate = NO;
        if (_shCamObj.isConnect) {
            [_shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }
        
        //清除相机的push msg信息及缓存的视频缩略图
//        MessageCenter *msgCenter = [MessageCenter MessageCenterWithName:_shCamObj.camera.cameraUid andMsgDelegate:nil];
//        [msgCenter clearAllMessage];
        
//        [[XJLocalAssetHelper sharedLocalAssetHelper] deleteLocalAllAssetsWithKey:cameraUid completionHandler:^(BOOL success) {
//            SHLogInfo(SHLogTagAPP, @"Delete local all asset is success: %d", success);
//        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    } else {
        message = NSLocalizedString(@"DeleteError", nil);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD showProgressHUDNotice:message showTime:2.0];
    });
}

- (void)unbindCameraWithCompletion:(void (^)())completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] unbindCameraWithCameraID:_shCamObj.camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"unbind camera is success: %d", isSuccess);
        
        if (isSuccess) {
            [weakself deleteCameraDetailWithCompletion:completion];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                
                [weakself showFailedTipsWithInfo:NSLocalizedString(@"kUnbindDeviceFailed", nil)/*@"解除账户相机绑定失败."*/];
            });
        }
    }];
}

- (void)unsubscribeCameraWithCompletion:(void (^)())completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] unsubscribeCameraWithCameraID:_shCamObj.camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"unsubscribe camera is success: %d", isSuccess);
        
        if (isSuccess) {
            [weakself deleteCameraDetailWithCompletion:completion];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                
                [weakself showFailedTipsWithInfo:NSLocalizedString(@"kUnsubscribeFailed", nil)/*@"取消订阅失败."*/];
            });
        }
    }];
}

- (void)showFailedTipsWithInfo:(NSString *)info {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:info/*NSLocalizedString(@"kUnregisterDeviceFailed", nil)*/ preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertC animated:YES completion:nil];
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
    [self fillAlbumTable];
}

- (void)fillDetailTable {
    [self.mainMenuDetailTable removeAllObjects];
    [self fillPushMsgStatusTable];
    [self fillTamperAlarmTable];
    
    // [self fillWiFiSettingTable];
    [self fillDeviceInfoTable];
}

- (void)fillDeviceInfoTable {
    SHSettingData *deviceInfoData = [[SHSettingData alloc] init];
    
    deviceInfoData.textLabel = NSLocalizedString(@"kDeviceInformation", nil);//@"Device Information";
    deviceInfoData.methodName = @"enterDeviceInfo:";
    
    if (deviceInfoData != nil) {
        [self.mainMenuDetailTable addObject:deviceInfoData];
    }
    
    // prepare device info
    [self fillVidRecDurationTable];
    [self fillSleepTimeTable];
    [self fillRecStatusTable];
    [self fillFasterConnectionTable];
    [self fillMemorySizeTable];
}

- (void)fillWiFiSettingTable {
    SHSettingData *wifiSettingData = [[SHSettingData alloc] init];
    
    wifiSettingData.textLabel = @"Wifi Setting";
    wifiSettingData.methodName = @"enterWiFiSetting:";
    
    if (wifiSettingData != nil) {
        [self.mainMenuDetailTable addObject:wifiSettingData];
    }
}

- (void)fillAlbumTable {
    SHSettingData *albumData = [[SHSettingData alloc] init];
    
    albumData.textLabel = NSLocalizedString(@"kSDcardAlbum", nil); //@"SD card album"; //NSLocalizedString(@"CameraAlbum", nil);
    albumData.methodName = @"enterAlbum";
    
    if (albumData != nil) {
        [self.mainMenuBasicTable addObject:albumData];
    }
}

- (void)fillDeleteCameraTable {
    [self.mainMenuDeleteCameraTable removeAllObjects];
    
    [self.mainMenuDeleteCameraTable addObject:@"Push Test"];
    [self.mainMenuDeleteCameraTable addObject:/*@"Delete"*/NSLocalizedString(@"Delete", nil)];
}

- (void)fillPushMsgStatusTable {
    SHSettingData *pushMsgStatusData = nil;
    
    if (_shCamObj.cameraProperty.pushMsgStatusData) {
        pushMsgStatusData = _shCamObj.cameraProperty.pushMsgStatusData;
    } else {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_PUSH_MSG_STATUS];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int pushMsgStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        pushMsgStatusData = [[SHSettingData alloc] init];
        pushMsgStatusData.textLabel = NSLocalizedString(@"SETTING_PUSH_MSG_STATUS", nil);
        pushMsgStatusData.detailLastItem = pushMsgStatus;
      
        _shCamObj.cameraProperty.pushMsgStatusData = pushMsgStatusData;
    }
    
    if (pushMsgStatusData) {
        [self.mainMenuDetailTable addObject:pushMsgStatusData];
    }
    
    [self syncMsgAndRecStatus];
}

- (void)syncMsgAndRecStatus {
    [self fillRecStatusTable];

    if (_shCamObj.cameraProperty.pushMsgStatusData == nil) {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_PUSH_MSG_STATUS];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int pushMsgStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        SHSettingData *pushMsgStatusData = [[SHSettingData alloc] init];
        pushMsgStatusData.textLabel = NSLocalizedString(@"SETTING_PUSH_MSG_STATUS", nil);
        pushMsgStatusData.detailLastItem = pushMsgStatus;
        
        _shCamObj.cameraProperty.pushMsgStatusData = pushMsgStatusData;
    }
    
    if (_shCamObj.cameraProperty.pushMsgStatusData.detailLastItem != _shCamObj.cameraProperty.recStatusData.detailLastItem) {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_VID_REC_STATUS];
        int recStatus = (int)_shCamObj.cameraProperty.pushMsgStatusData.detailLastItem;
        
        BOOL ret = [itemData changeRangeItemValueWithPropertyID:0 andNewValue:recStatus];
        
        if (!ret) {
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", @"") showTime:2.0];
        } else {
            _shCamObj.cameraProperty.recStatusData.detailLastItem = recStatus;
            _shCamObj.cameraProperty.recStatusData.detailTextLabel = recStatus ? NSLocalizedString(@"SETTING_ON", nil) : NSLocalizedString(@"SETTING_OFF", nil); //@"On" : @"Off";
        }
    }
    
    [self detPirStatusHandler];
}

- (void)detPirStatusHandler {
    SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_PIR_STATUS];
    itemData.curResult = self.curResult;
    itemData.rangeResult = self.supResult;
    
    int detPirStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
    SHLogInfo(SHLogTagAPP, @"Det pir status: %d", detPirStatus);
    
    if (detPirStatus != _shCamObj.cameraProperty.pushMsgStatusData.detailLastItem) {
        BOOL ret = [itemData changeRangeItemValueWithPropertyID:0 andNewValue:(int)_shCamObj.cameraProperty.pushMsgStatusData.detailLastItem];
        
        if (!ret) {
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", @"") showTime:2.0];
        }
    }
}

- (void)fillTamperAlarmTable {
    SHSettingData *tamperalarmData = nil;
    
    if (_shCamObj.cameraProperty.tamperalarmData) {
        tamperalarmData = _shCamObj.cameraProperty.tamperalarmData;
    } else {
        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_TAMPER_ALARM];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int tamperalarm = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        tamperalarmData = [[SHSettingData alloc] init];
        tamperalarmData.textLabel = NSLocalizedString(@"kTamperAlarm", nil);
        tamperalarmData.detailLastItem = tamperalarm;
        
        _shCamObj.cameraProperty.tamperalarmData = tamperalarmData;
    }
    
    if (tamperalarmData) {
        [self.mainMenuDetailTable addObject:tamperalarmData];
    }
}

#pragma mark - Device Information Data
- (void)fillVidRecDurationTable {
    if (_shCamObj.cameraProperty.vidRecDurationData == nil) {
        SHVidRecDuration *rd = [SHVidRecDuration vidRecDurationWithCamera:_shCamObj];
        rd.curResult = self.curResult;
        rd.rangeResult = self.supResult;
        
        _shCamObj.cameraProperty.vidRecDurationData = [rd prepareDataForVidRecDuration];
    }
}

- (void)fillSleepTimeTable {
    if (_shCamObj.cameraProperty.sleepTimeData == nil) {
        SHSleepTime *st = [SHSleepTime sleepTimeWithCamera:_shCamObj];
        st.curResult = self.curResult;
        st.rangeResult = self.supResult;
        
        _shCamObj.cameraProperty.sleepTimeData = [st prepareDataForSleepTime];
    }
}

- (void)fillRecStatusTable {
    if (_shCamObj.cameraProperty.recStatusData == nil) {
        SHSettingData *recStatusData = nil;

        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_DET_VID_REC_STATUS];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int recStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        recStatusData = [[SHSettingData alloc] init];
        recStatusData.textLabel = NSLocalizedString(@"SETTING_REC_STATUS", nil);
        recStatusData.detailLastItem = recStatus;
        recStatusData.detailTextLabel = recStatus ? NSLocalizedString(@"SETTING_ON", nil) : NSLocalizedString(@"SETTING_OFF", nil); //@"On" : @"Off";

        _shCamObj.cameraProperty.recStatusData = recStatusData;
    }
}

- (void)fillFasterConnectionTable {
    if (_shCamObj.cameraProperty.fasterConnectionData == nil) {
        SHSettingData *fasterConnectionData = nil;

        SHRangeItemData *itemData = [SHRangeItemData rangeItemDataWithCamera:_shCamObj andPropertyID:TRANS_PROP_CAMERA_ULTRA_POWER_SAVING_MODE];
        itemData.curResult = self.curResult;
        itemData.rangeResult = self.supResult;
        
        int fasterConStatus = [itemData retrieveRangeItemCurrentValueWithPropertyID:0];
        
        fasterConnectionData = [[SHSettingData alloc] init];
        fasterConnectionData.textLabel = NSLocalizedString(@"SETTING_ULTRA_POWER_SAVING_MODE", nil);
        //        fasterConnectionData.detailLastItem = pushMsgStatus;
        fasterConnectionData.detailTextLabel = fasterConStatus ? NSLocalizedString(@"SETTING_ON", nil) : NSLocalizedString(@"SETTING_OFF", nil); //@"On" : @"Off";

        _shCamObj.cameraProperty.fasterConnectionData = fasterConnectionData;
    }
}

- (void)fillMemorySizeTable {
    if (_shCamObj.cameraProperty.memorySizeData == nil) {
        SHSettingData *memorySizeData = nil;

        int memorySize = [_shCamObj.controler.propCtrl retrieveSDCardFreeSpaceSizeWithCamera:_shCamObj curResult:nil];
        
        memorySizeData = [[SHSettingData alloc] init];
        // memorySizeData.textLabel = NSLocalizedString(@"SETTING_MEMORY_SIZE", nil);
        memorySizeData.textLabel = NSLocalizedString(@"SETTING_MEMORY_SIZE", nil);
        memorySizeData.detailTextLabel = memorySize == -1 ? /*@"no card"*/NSLocalizedString(@"kNoSDcard", nil) : [DiskSpaceTool transformStringFromMBytes:memorySize]; //[NSString stringWithFormat:@"%d MB", memorySize];
        memorySizeData.detailLastItem = memorySize;

        _shCamObj.cameraProperty.memorySizeData = memorySizeData;
    }
}

#pragma mark - init
- (SHPropertyQueryResult *)curResult {
    if (!_curResult) {
        _curResult = [_ctrl.propCtrl retrieveSettingCurPropertyWithCamera:_shCamObj];
    }
    
    return _curResult;
}

//- (SHPropertyQueryResult *)supResult {
//    if (!_supResult) {
//        _supResult = nil; //[_ctrl.propCtrl retrieveSettingSupPropertyWithCamera:_shCamObj];
//    }
//
//    return _supResult;
//}

- (NSMutableArray *)mainMenuTable {
    if (!_mainMenuTable) {
        _mainMenuTable = [NSMutableArray array];
    }
    
    return _mainMenuTable;
}

- (NSMutableArray *)mainMenuBasicTable {
    if (!_mainMenuBasicTable) {
        _mainMenuBasicTable = [NSMutableArray array];
    }
    
    return _mainMenuBasicTable;
}

- (NSMutableArray *)mainMenuDetailTable {
    if (_mainMenuDetailTable == nil) {
        _mainMenuDetailTable = [NSMutableArray array];
    }
    
    return _mainMenuDetailTable;
}

- (NSMutableArray *)mainMenuDeleteCameraTable {
    if (_mainMenuDeleteCameraTable == nil) {
        _mainMenuDeleteCameraTable = [NSMutableArray arrayWithCapacity:1];
    }
    
    return _mainMenuDeleteCameraTable;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [MBProgressHUD progressHUDWithView:self.view.window];
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

@end
