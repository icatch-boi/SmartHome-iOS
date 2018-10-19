//
//  SHMpbTVC.m
//  SmartHome
//
//  Created by ZJ on 2017/4/14.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHMpbTVC.h"
#import "SHMpbTVCPrivate.h"
#import "HWCalendar.h"
#import "SHMpbTableViewCell.h"
#import "SHMpbHeaderView.h"
#import "SHVideoPlaybackVC.h"
#import "MpbPopoverViewController.h"
#import "SHFilterTableViewCell.h"
#import "SHSDKEventListener.hpp"
#import "SHFileDownloadTVC.h"
#import "SHGUIHandleTool.h"
#import "SHDownloadManager.h"

static int const kNewFileIconWidth = 10.0;
static int const kNewFileIconTag = 888;

@interface SHMpbTVC () <HWCalendarDelegate, UITableViewDelegate, UITableViewDataSource, VideoPlaybackControllerDelegate, CustomIOS7AlertViewDelegate>

@property (nonatomic, weak) HWCalendar *calendar;
@property (nonatomic, strong) NSMutableArray *storageInfoArray;
@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property (nonatomic, copy) NSString *latestFileDate;

@end

@implementation SHMpbTVC

#pragma mark - initVariable
// 懒加载
//图片缓存
- (NSCache *)mpbCache {
    if (_mpbCache == nil) {
        _mpbCache = [[NSCache alloc] init];
        _mpbCache.countLimit = 100;
        _mpbCache.totalCostLimit = 4096;
    }
    
    return _mpbCache;
}
//日期和对应是否有文件8天
- (NSMutableArray *)storageInfoArray {
    if (!_storageInfoArray) {
        _storageInfoArray = [NSMutableArray arrayWithCapacity:8];
    }
    
    return _storageInfoArray;
}

//?cellTable是什么？
- (SHTableViewSelectedCellTable *)selCellsTable {
    if (!_selCellsTable) {
        _selCellsTable = [_ctrl.fileCtrl createOneCellsTable];
    }
    
    return _selCellsTable;
}


- (dispatch_semaphore_t)mpbSemaphore {
    if (!_mpbSemaphore) {
        _mpbSemaphore = dispatch_semaphore_create(1);
    }
    
    return _mpbSemaphore;
}

- (dispatch_queue_t)thumbnailQueue {
    if (!_thumbnailQueue) {
        _thumbnailQueue = dispatch_queue_create("SmartHome.GCD.Queue.Playback.Thumbnail", 0);
    }
    
    return _thumbnailQueue;
}

- (dispatch_queue_t)downloadQueue {
    if (!_downloadQueue) {
        _downloadQueue = dispatch_queue_create("SmartHoem.GCD.Queue.Playback.Download", 0);
    }
    
    return _downloadQueue;
}

- (dispatch_queue_t)downloadPercentQueue {
    if (!_downloadPercentQueue) {
        _downloadPercentQueue = dispatch_queue_create("SmartHome.GCD.Queue.Playback.DownloadPercent", 0);
    }
    
    return _downloadPercentQueue;
}

//全部过滤条件
- (NSArray *)filterArray {
    if (!_filterArray) {
        _filterArray = [SHTool registerDefaultsFromSHFileFilter];
    }
    
    return _filterArray;
}

//选中的过滤条件
- (NSMutableArray *)selectedFilterCells {
    if (!_selectedFilterCells) {
        _selectedFilterCells = [NSMutableArray array];
    }
    
    return _selectedFilterCells;
}


- (SHDatabase *)db {
    if (!_db) {
        _db = [SHDatabase databaseWithDatabaseName:_shCamObj.camera.cameraUid.md5];
    }
    
    return _db;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = _shCamObj.controler;
    //获取fw时间
    self.remoteDateTime = [self getRemoteDateTime];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;//不需要显示分割线
    [self setCorner];
    [self initMpbGUI];
    [self creatCalendar];
    [self initPhotoGallery];
    
    //    [self stringToDate:@"2017/04/20 11:11:11" andFormat:kDateFormat]
    [self updateShowDate:_remoteDateTime];
    [self addCameraPropertyValueChangeBlock];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (!_shCamObj.isConnect) {
        [self goHome:nil];
        
        return;
    }
    
    self.run = YES;
    
//    if (_curMpbState == SHMpbStateNor || _isDownloading) {
	if (_curMpbState == SHMpbStateNor) {
        [self clearSelectedCellTable];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recoverFromDisconnection) name:kCameraNetworkConnectedNotification object:nil];
}

- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
    SHFile *file = tempDict[@"file"];
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"kFileDownloadCompleteTipsInfo", nil), tempDict[@"cameraName"], file.f.getFileName().c_str()];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.notificationView showGCDNoteWithMessage:msg andTime:kShowDownloadCompleteNoteTime withAcvity:NO];
    });
}

- (void)recoverFromDisconnection {
    SHCameraManager *app = [SHCameraManager sharedCameraManger];
    self.shCamObj = [app getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = _shCamObj.controler;
    
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    if (_isDownloading || _readyGoToFileDownloadVC) {
//        _readyGoToFileDownloadVC = NO;
//        return;
//    }
	
    self.curDate = [_remoteDateTime convertToStringWithFormat:kDateFormat];//[SHGUIHandleTool dateToString:_remoteDateTime andFormat:kDateFormat];
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
 
    [_shCamObj.gallery resetPhotoGalleryDataWithStartDate:self.curDate endDate:nil judge:YES completeBlock:^(id obj) {
        self.storageInfoArray = obj;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            [self initMpbGUI];
            [self updateMpbGUI];
        });
    }];
}

-(void)viewWillLayoutSubviews {
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")
        && !_filterView.hidden) {
        [_filterView updatePositionForDialogView];
    }
    [super viewWillLayoutSubviews];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.run = NO;
    [self.db closeDatabase];
    self.db = nil;
    
    if (_selCellsTable.count > 0) {
        //        [self.selCellsTable removeObserver:self forKeyPath:@"count"];
    }
    
    if (!_filterView.hidden) {
        _filterView.hidden = YES;
    }
    
    NSDate *date = [self getRemoteDateTime];
    NSString *tempTime = [date convertToStringWithFormat:kDateFormat];
    if (![tempTime isEqualToString:_shCamObj.camera.pbTime] || _shCamObj.camera.pbTime == nil) {
        _shCamObj.camera.pbTime = tempTime;
        
        // Save data to sqlite
        NSError *error = nil;
        if (![_shCamObj.camera.managedObjectContext save:&error]) {
            SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
            abort();
#endif
        } else {
            SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
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

- (void)clearSelectedCellTable {
    for (NSIndexPath *ip in _selCellsTable.selectedCells) {
        SHMpbTableViewCell *cell = (SHMpbTableViewCell *)[self.tableView cellForRowAtIndexPath:ip];
        [cell setSelectedConfirmIconHidden:YES];
        cell.tag = 0;
    }
    
    [_selCellsTable.selectedCells removeAllObjects];
    self.selCellsTable.count = 0;
}

#pragma mark - initGUI & Data
- (void)initPhotoGallery {
    self.title = NSLocalizedString(@"Albums", @"");
    self.editButton.title = NSLocalizedString(@"Edit", @"");
    self.footerView.alpha = 0;
}


- (void)setCorner {
    [SHGUIHandleTool setButtonRadius:_firstButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_secondButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_thirdButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_fourthButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_fifthButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_sixthButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_seventhButton withRadius:kButtonRadius];
    [SHGUIHandleTool setButtonRadius:_eighthButton withRadius:kButtonRadius];
    
    [_firstView setCornerWithRadius:kViewRadius];
    [_secondView setCornerWithRadius:kViewRadius];
    [_thirdView setCornerWithRadius:kViewRadius];
    [_fourthView setCornerWithRadius:kViewRadius];
    [_fifthView setCornerWithRadius:kViewRadius];
    [_sixthView setCornerWithRadius:kViewRadius];
    [_seventhView setCornerWithRadius:kViewRadius];
    [_eighthView setCornerWithRadius:kViewRadius];
}

- (void)initMpbGUI {
    [self initViewStatus:_firstView];
    [self initViewStatus:_secondView];
    [self initViewStatus:_thirdView];
    [self initViewStatus:_fourthView];
    [self initViewStatus:_fifthView];
    [self initViewStatus:_sixthView];
    [self initViewStatus:_seventhView];
    [self initViewStatus:_eighthView];
    
    [self initButtonStatus:_firstButton];
    [self initButtonStatus:_secondButton];
    [self initButtonStatus:_thirdButton];
    [self initButtonStatus:_fourthButton];
    [self initButtonStatus:_fifthButton];
    [self initButtonStatus:_sixthButton];
    [self initButtonStatus:_seventhButton];
    [self initButtonStatus:_eighthButton];
    
    if (self.storageInfoArray.count) {
        _editButton.enabled = YES;
    } else {
        _editButton.enabled = NO;
    }
}

- (void)initViewStatus:(UIView *)view {
    [SHGUIHandleTool setViewHidden:YES andView:view];
}

- (void)initButtonStatus:(UIButton *)btn {
    [SHGUIHandleTool setButtonEnabled:NO andButton:btn];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:btn];
    [SHGUIHandleTool setButtonTitleColor:[UIColor grayColor] andButton:btn];
}

- (void)initButtonBackgroundColor {
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_firstButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_secondButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_thirdButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_fourthButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_fifthButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_sixthButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_seventhButton];
    [SHGUIHandleTool setButtonBackgroundColor:[UIColor clearColor] andButton:_eighthButton];
}

- (void)updateMpbGUI {
    SHFileTable *tempTable = nil;
    for (int i = 0; i < self.storageInfoArray.count; i++) {
        tempTable = self.storageInfoArray[i];
        [self setMpbGUIDisplay:tempTable.fileCreateDate];
    }
    
    _curFileTable = tempTable;
    [self updateButtonBackgroundColor:_curFileTable.fileCreateDate];
    [self.tableView reloadData];
}

//日期按钮的背景设置，表示当前日期
- (void)updateButtonBackgroundColor:(NSString *)date {
    NSString *day = [date substringFromIndex:8];
    //    SHLogInfo(SHLogTagAPP, @"day: %@", day);
    int temp = [day intValue];
    
    [self initButtonBackgroundColor];
    
    UIButton *btn = nil;
    
    if (temp == [self getButtonTitle:_firstButton]) {
        btn = _firstButton;
    } else if (temp == [self getButtonTitle:_secondButton]) {
        btn = _secondButton;
    } else if (temp == [self getButtonTitle:_thirdButton]) {
        btn = _thirdButton;
    } else if (temp == [self getButtonTitle:_fourthButton]) {
        btn = _fourthButton;
    } else if (temp == [self getButtonTitle:_fifthButton]) {
        btn = _fifthButton;
    } else if (temp == [self getButtonTitle:_sixthButton]) {
        btn = _sixthButton;
    } else if (temp == [self getButtonTitle:_seventhButton]) {
        btn = _seventhButton;
    } else if (temp == [self getButtonTitle:_eighthButton]) {
        btn = _eighthButton;
    }
    
    if (btn) {
        [SHGUIHandleTool setButtonBackgroundColor:kBackgroundColor andButton:btn];
    }
}
//设置日期栏的显示，有点无点，文字颜色，是否可以点击，背景？
- (void)setMpbGUIDisplay:(NSString *)key {
    NSString *day = [key substringFromIndex:8];
    //    SHLogInfo(SHLogTagAPP, @"day: %@", day);
    
    int temp = [day intValue];
    
    if (temp == [self getButtonTitle:_firstButton]) {
        [self setMpbSceneWith:_firstButton andView:_fifthView];
    } else if (temp == [self getButtonTitle:_secondButton]) {
        [self setMpbSceneWith:_secondButton andView:_secondView];
    } else if (temp == [self getButtonTitle:_thirdButton]) {
        [self setMpbSceneWith:_thirdButton andView:_thirdView];
    } else if (temp == [self getButtonTitle:_fourthButton]) {
        [self setMpbSceneWith:_fourthButton andView:_fourthView];
    } else if (temp == [self getButtonTitle:_fifthButton]) {
        [self setMpbSceneWith:_fifthButton andView:_fifthView];
    } else if (temp == [self getButtonTitle:_sixthButton]) {
        [self setMpbSceneWith:_sixthButton andView:_sixthView];
    } else if (temp == [self getButtonTitle:_seventhButton]) {
        [self setMpbSceneWith:_seventhButton andView:_seventhView];
    } else if (temp == [self getButtonTitle:_eighthButton]) {
        [self setMpbSceneWith:_eighthButton andView:_eighthView];
    }
}

- (int)getButtonTitle:(UIButton *)btn {
    int temp = [btn.currentTitle intValue];
    //    SHLogInfo(SHLogTagAPP, @"btnTitle: %d", temp);
    return temp;
}

- (void)setMpbSceneWith:(UIButton *)btn andView:(UIView *)view {
    [SHGUIHandleTool setViewHidden:NO andView:view];
    [SHGUIHandleTool setButtonEnabled:YES andButton:btn];
    [SHGUIHandleTool setButtonTitleColor:[UIColor blackColor] andButton:btn];
}

//显示月份和生成日期队列
- (void)updateShowDate:(NSDate *)curDate {
    NSMutableArray *dateArray = [[NSMutableArray alloc] initWithCapacity:8];
    NSDateFormatter *dateformatter_D = [[NSDateFormatter alloc] init];
    [dateformatter_D setDateFormat:@"dd"];
    
    NSDateFormatter *dateformatter_M = [[NSDateFormatter alloc] init];
    [dateformatter_M setDateFormat:@"MM"];
    
    NSString *curMonth = [dateformatter_M stringFromDate:curDate];
    dispatch_async(dispatch_get_main_queue(), ^{
        _titleLabel.text = [NSString stringWithFormat:@"%@%@", curMonth, NSLocalizedString(@"kMonth", nil)];
    });
    
    BOOL done = NO;
    
    for (int i = 0; i < 8; i++) {
        //单位为秒
        NSDate *date = [NSDate dateWithTimeInterval:-24 * 60 * 60 * i sinceDate:curDate];
        NSString *day = [dateformatter_D stringFromDate:date];
        [dateArray addObject:day];
        
        NSString *month = [dateformatter_M stringFromDate:date];
        if (![month isEqualToString:curMonth]) {
            if (!done) {
                //夸月处理
                dispatch_async(dispatch_get_main_queue(), ^{
                    _titleLabel.text = [NSString stringWithFormat:@"%@%@/%@%@", month, NSLocalizedString(@"kMonth", nil), curMonth, NSLocalizedString(@"kMonth", nil)];
                });
                done = YES;
            }
        }
    }
    
    [_firstButton setTitle:dateArray[7] forState:UIControlStateNormal];
    [_secondButton setTitle:dateArray[6] forState:UIControlStateNormal];
    [_thirdButton setTitle:dateArray[5] forState:UIControlStateNormal];
    [_fourthButton setTitle:dateArray[4] forState:UIControlStateNormal];
    [_fifthButton setTitle:dateArray[3] forState:UIControlStateNormal];
    [_sixthButton setTitle:dateArray[2] forState:UIControlStateNormal];
    [_seventhButton setTitle:dateArray[1] forState:UIControlStateNormal];
    [_eighthButton setTitle:dateArray[0] forState:UIControlStateNormal];
    
}

- (void)creatCalendar
{
    //日历
    HWCalendar *calendar = [[HWCalendar alloc] initWithFrame:CGRectMake(7, [UIScreen screenHeight], 400, 396) andCurDateTime:_remoteDateTime cameraObj:_shCamObj];
    calendar.hidden = YES;
    calendar.delegate = self;
    calendar.showTimePicker = YES;
    
    [self.view addSubview:calendar];
    self.calendar = calendar;
}

//获取fw日期
- (NSDate *)getRemoteDateTime {
    SHGettingProperty *rdtPro = [SHGettingProperty gettingPropertyWithControl:_shCamObj.sdk.control];
    [rdtPro addProperty:TRANS_PROP_REMOTE_DATE_TIME];
    SHPropertyQueryResult *result = [rdtPro submit];
    
    NSString *rDate = [result praseString:TRANS_PROP_REMOTE_DATE_TIME];
    SHLogInfo(SHLogTagAPP, @"getRemoteDateTime: %@", rDate);
    //"yyyy/MM/dd HH:mm:ss"
    NSDate *rdt = [rDate convertToDateWithFormat:kDateFormat];//[SHGUIHandleTool stringToDate:rDate andFormat:kDateFormat];
    
    return rdt ? rdt : [NSDate date];
}

#pragma mark - favoriteOperate

- (void)setSelectFileFavorite:(BOOL)isFavorite {
    bool favorite = isFavorite ? true : false;
    
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (_selCellsTable.count) {
            for (NSIndexPath *ip in _selCellsTable.selectedCells) {
                vector<ICatchFile> tempFileList = _curFileTable.fileList;
                ICatchFile *f = &(tempFileList.at(ip.row));
                
              
                if (f->getFileFavorite() == favorite) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressHUD hide:YES];
                        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kDonotRepeatSetting", nil) showTime:2.0];
                    });
                    return;
                }
                
                if ([_ctrl.fileCtrl setSelectFileTag:f andIsFavorite:isFavorite]) {
                    f->setFileFavorite(favorite);//特别注意，需要本地设置保存
                    SHLogDebug(SHLogTagAPP, @"f.getFileFavorite: %d", f->getFileFavorite());
                    
                    _curFileTable.fileList = tempFileList;
                    SHLogDebug(SHLogTagAPP, @"_curFileTable.fileList.at(ip.row).getFileFavorite: %d", _curFileTable.fileList.at(ip.row).getFileFavorite());
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressHUD hide:YES];
                        [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationAutomatic];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.progressHUD hide:YES];
                        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kSettingFailed", nil) showTime:2.0];
                    });
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // clear
                [self clearSelectedCellTable];
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kSelectedItem", nil) showTime:1.5];
            });
        }
    });
}

- (IBAction)favoriteAction:(id)sender {
    SHLogTRACE();
    
    [self setSelectFileFavorite:YES];
}

- (IBAction)unfavoriteAction:(id)sender {
    SHLogTRACE();
    
    [self setSelectFileFavorite:NO];
}

#pragma mark - deleteOperate

- (IBAction)deleteAction:(id)sender {
    SHLogTRACE();
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    if (!_selCellsTable.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kSelectedItem", nil) showTime:1.5];
        });
        return;
    }
    
    NSString *message = NSLocalizedString(@"DeleteMultiAsk", nil);
    NSString *replaceString = [NSString stringWithFormat:@"%ld", (long)_selCellsTable.count];
    message = [message stringByReplacingOccurrencesOfString:@"%d"
                                                 withString:replaceString];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self showPopoverFromBarButtonItem:sender
                                   message:message
                           fireButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                  callback:@selector(deleteDetail:)];
    } else {
        [self showActionSheetFromBarButtonItem:sender
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:NSLocalizedString(@"SureDelete", @"")
                                           tag:ACTION_SHEET_DELETE_ACTIONS];
    }
}



- (void)showPopoverFromBarButtonItem:(UIButton *)item
                             message:(NSString *)message
                     fireButtonTitle:(NSString *)fireButtonTitle
                            callback:(SEL)fireAction
{
    SHLogTRACE();
    
    MpbPopoverViewController *contentViewController = [[MpbPopoverViewController alloc] initWithNibName:@"MpbPopover" bundle:nil];
    contentViewController.msg = message;
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        contentViewController.msgColor = [UIColor blackColor];
    } else {
        contentViewController.msgColor = [UIColor whiteColor];
    }
    UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:contentViewController];
    if (fireButtonTitle) {
        UIButton *fireButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 110.0f, 260.0f, 47.0f)];
        popController.popoverContentSize = CGSizeMake(270.0f, 170.0f);
        fireButton.enabled = YES;
        
        [fireButton setTitle:fireButtonTitle
                    forState:UIControlStateNormal];
        [fireButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f]
                              forState:UIControlStateNormal];
        [fireButton addTarget:self action:fireAction forControlEvents:UIControlEventTouchUpInside];
        [contentViewController.view addSubview:fireButton];
    } else {
        popController.popoverContentSize = CGSizeMake(270.0f, 160.0f);
    }
    
    self.popController = popController;
    //    [_popController presentPopoverFromBarButtonItem:item permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    [_popController presentPopoverFromRect:item.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showActionSheetFromBarButtonItem:(UIButton *)item
                                 message:(NSString *)message
                       cancelButtonTitle:(NSString *)cancelButtonTitle
                  destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                     tag:(NSInteger)tag
{
    SHLogTRACE();
    
    self.actionSheet = [UIAlertController alertControllerWithTitle:message message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [_actionSheet addAction:[UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:nil]];
    if (destructiveButtonTitle != nil) {
        [_actionSheet addAction:[UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            switch (tag) {
                case ACTION_SHEET_DOWNLOAD_ACTIONS:
                    [self downloadDetail:item];
                    break;
                    
                case ACTION_SHEET_DELETE_ACTIONS:
                    [self deleteDetail:item];
                    break;
                    
                default:
                    break;
            }
        }]];
    }
    
    [self presentViewController:_actionSheet animated:YES completion:nil];
}

//should update file count in storage info when remove files
- (void)deleteDetail:(id)sender {
    SHLogTRACE();
    __block int failedCount = 0;
    
    if ([sender isKindOfClass:[UIButton self]]) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    self.run = NO;
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"Deleting", nil)
                                  detailsMessage:nil
                                            mode:MBProgressHUDModeIndeterminate];
    
	//  NSMutableArray *toDeletedIndexPaths = [[NSMutableArray alloc] init];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		//        NSString *cachedKey = nil;
		
		dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 10ull * NSEC_PER_SEC);
		dispatch_semaphore_wait(self.mpbSemaphore, time);
		
		// Real delete icatch file & remove NSCache item
		
		vector<ICatchFile> *tempFileList = new vector<ICatchFile>(_curFileTable.fileList);
        NSInteger curFileNum = _curFileTable.fileList.size();
		int ii = 0;
		for (NSIndexPath *ip in _selCellsTable.selectedCells) {
			//      int type = [[a objectAtIndex:1] intValue];
			ICatchFile f = _curFileTable.fileList.at(ip.row);
			//ICatchFile *file = (ICatchFile *)[[a lastObject] pointerValue];
			if ([_ctrl.fileCtrl deleteFile:&f] == NO) {
				++failedCount;
			}else{
				[self.db deleteFromDataBaseWithFileHandle:f.getFileHandle()];
				[_ctrl.propCtrl updateSDCardFreeSpaceSizeWithCamera:_shCamObj];
				tempFileList->erase(tempFileList->begin() + (ip.row-ii));
				ii++;
			}
		}
		
        // Update the UICollectionView's data source
        _curFileTable.fileList = *tempFileList;
        _curFileTable.fileStorage = [SHTool calcFileSize:*tempFileList];
        
        [self.storageInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SHFileTable *table = obj;
            if ([_curFileTable.fileCreateDate isEqualToString:table.fileCreateDate]) {
                if (!_curFileTable.fileStorage) {
                    _curFileTable.fileCreateDate = nil;
                }
                self.storageInfoArray[idx] = _curFileTable;
                *stop = YES;
            }
        }];
        //        [self resetTableViewCellDataWithDate:self.curDate];
        
        dispatch_semaphore_signal(self.mpbSemaphore);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (failedCount != _selCellsTable.selectedCells.count) {
                if (failedCount == 0 && (_selCellsTable.selectedCells.count == curFileNum)) {
                    [self editAction:nil];
                }
                
                [_selCellsTable.selectedCells removeAllObjects];
                _selCellsTable.count = 0;
                self.run = YES;
                [self initMpbGUI];
                [self updateMpbGUI];
                //                [self.tableView reloadData];
            }
            
            NSString *noticeMessage = nil;
            
            if (failedCount > 0) {
                noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
                NSString *failedCountString = [NSString stringWithFormat:@"%d", failedCount];
                noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
            } else {
                noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
            }
            [self.progressHUD showProgressHUDCompleteMessage:noticeMessage];
        });
    });
}

- (BOOL)delectFileAtIndex:(NSUInteger)index {
    NSUInteger i = 0;
    unsigned long listSize = 0;
    BOOL ret = NO;
    
    vector<ICatchFile> tempFileList = _curFileTable.fileList;
    listSize = tempFileList.size();
    
    if (listSize > 0) {
        i = MAX(0, MIN(index, listSize - 1));
        
        ICatchFile file = tempFileList.at(i);
        ret = [_ctrl.fileCtrl deleteFile:&file];
        if (ret) {
            [self.db deleteFromDataBaseWithFileHandle:file.getFileHandle()];
            [_ctrl.propCtrl updateSDCardFreeSpaceSizeWithCamera:_shCamObj];
            tempFileList.erase(tempFileList.begin() + i);
            
            _curFileTable.fileList = tempFileList;
            _curFileTable.fileStorage = [SHTool calcFileSize:tempFileList];
            
            [self.storageInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHFileTable *table = obj;
                if ([_curFileTable.fileCreateDate isEqualToString:table.fileCreateDate]) {
                    if (!_curFileTable.fileStorage) {
                        _curFileTable.fileCreateDate = nil;
                    }
                    self.storageInfoArray[idx] = _curFileTable;
                    *stop = YES;
                }
            }];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!_curFileTable.fileStorage) {
                [self initMpbGUI];
                [self updateMpbGUI];
            }
            
            NSString *noticeMessage = nil;
            
            if (!ret) {
                noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
                NSString *failedCountString = @"1";
                noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
            } else {
                noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
            }
            
            [self.progressHUD showProgressHUDCompleteMessage:noticeMessage];
        });
    }
    
    return ret;
}

#pragma mark - downloadOperate
- (IBAction)downloadAction:(id)sender {
    SHLogTRACE();
    
    if (_popController.popoverVisible) {
        [_popController dismissPopoverAnimated:YES];
    }
    
    if (!_selCellsTable.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kSelectedItem", nil) showTime:1.5];
        });
        return;
    }
    
    NSInteger fileNum = 0;
    unsigned long long downloadSizeInKBytes = 0;
    NSString *confrimButtonTitle = nil;
    NSString *message = nil;
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    
    if (_curMpbState == SHMpbStateEdit) {
        
        if (_totalDownloadSize < freeDiscSpace/2.0) {
            message = [self makeupDownloadMessageWithSize:_totalDownloadSize
                                                andNumber:_selCellsTable.count];
            confrimButtonTitle = NSLocalizedString(@"SureDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:_totalDownloadSize];
        }
        
    } else {
        
        fileNum = _curFileTable.fileList.size();
        downloadSizeInKBytes = _curFileTable.fileStorage;
        
        if (downloadSizeInKBytes < freeDiscSpace) {
            message = [self makeupDownloadMessageWithSize:downloadSizeInKBytes
                                                andNumber:fileNum];
            confrimButtonTitle = NSLocalizedString(@"AllDownload", @"");
        } else {
            message = [self makeupNoDownloadMessageWithSize:downloadSizeInKBytes];
        }
        
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [_activityViewController dismissViewControllerAnimated:YES completion:nil];
        [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
    } else {
        [_activityViewController dismissViewControllerAnimated:YES completion:^{
            [self _showDownloadConfirm:message title:confrimButtonTitle dBytes:downloadSizeInKBytes fSpace:freeDiscSpace];
        }];
    }
}
//默认按照1M/s来计算下载速度，产生需要多少时间的message
- (NSString *)makeupDownloadMessageWithSize:(unsigned long long)sizeInKB
                                  andNumber:(NSInteger)num
{
    SHLogTRACE();
    
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    unsigned long long downloadTimeInHours = (sizeInKB/1024)/3600;
    unsigned long long downloadTimeInMinutes = (sizeInKB/1024)/60 - downloadTimeInHours*60;
    unsigned long long downloadTimeInSeconds = sizeInKB/1024 - downloadTimeInHours*3600 - downloadTimeInMinutes*60;
    SHLogInfo(SHLogTagAPP, @"downloadTimeInHours: %llu, downloadTimeInMinutes: %llu, downloadTimeInSeconds: %llu",
              downloadTimeInHours, downloadTimeInMinutes, downloadTimeInSeconds);
    
    if (downloadTimeInHours > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage3", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInHours]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%4"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else if (downloadTimeInMinutes > 0) {
        message = NSLocalizedString(@"DownloadConfirmMessage2", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInMinutes]];
        message = [message stringByReplacingOccurrencesOfString:@"%3"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    } else {
        message = NSLocalizedString(@"DownloadConfirmMessage1", nil);
        message = [message stringByReplacingOccurrencesOfString:@"%1"
                                                     withString:[NSString stringWithFormat:@"%ld", (long)num]];
        message = [message stringByReplacingOccurrencesOfString:@"%2"
                                                     withString:[NSString stringWithFormat:@"%llu", downloadTimeInSeconds]];
    }
    message = [message stringByAppendingString:[NSString stringWithFormat:@"\n%@", humanDownloadFileSize]];
    return message;
    
}

- (NSString *)makeupNoDownloadMessageWithSize:(unsigned long long)sizeInKB
{
    SHLogTRACE();
    NSString *message = nil;
    NSString *humanDownloadFileSize = [_ctrl.comCtrl translateSize:sizeInKB];
    double freeDiscSpace = [_ctrl.comCtrl freeDiskSpaceInKBytes];
    NSString *leftSpace = [_ctrl.comCtrl translateSize:freeDiscSpace];
    message = [NSString stringWithFormat:@"%@\n Download:%@, Free:%@", NSLocalizedString(@"NotEnoughSpaceError", nil), humanDownloadFileSize, leftSpace];
    message = [message stringByAppendingString:@"\n Needs double free space"];
    return message;
}

-(void)_showDownloadConfirm:(NSString *)message
                      title:(NSString *)confrimButtonTitle
                     dBytes:(unsigned long long)downloadSizeInKBytes
                     fSpace:(double)freeDiscSpace {
    SHLogTRACE();
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (downloadSizeInKBytes < freeDiscSpace) {
            [self showPopoverFromBarButtonItem:self.downloadButton
                                       message:message
                               fireButtonTitle:confrimButtonTitle
                                      callback:@selector(downloadDetail:)];
        } else {
            [self showPopoverFromBarButtonItem:self.downloadButton
                                       message:message
                               fireButtonTitle:nil
                                      callback:nil];
        }
        
    } else {
        [self showActionSheetFromBarButtonItem:self.downloadButton
                                       message:message
                             cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                        destructiveButtonTitle:confrimButtonTitle
                                           tag:ACTION_SHEET_DOWNLOAD_ACTIONS];
    }
}

- (void)downloadDetail:(id)sender {
    SHLogTRACE();
	if(_popController != nil){
		[_popController dismissPopoverAnimated:YES];
	}

#if 0
    for (NSIndexPath *ip in _selCellsTable.selectedCells) {
        ICatchFile f = _curFileTable.fileList.at(ip.row);
		NSString *uid = _shCamObj.camera.cameraUid;
		SHFile *file = [SHFile fileWithUid:uid file:f];
		[[SHDownloadManager shareDownloadManger] addDownloadFile:file];
		//
//		if([[SHDownloadManager shareDownloadManger].downloadArray containsObject:file] == NO){
//			[[SHDownloadManager shareDownloadManger].downloadArray addObject:file];
//		}
    }
    [[SHDownloadManager shareDownloadManger] startDownloadFile];
    [self clearSelectedCellTable];
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.isDownloading = YES;
//        self.readyGoToFileDownloadVC = YES;
        [self performSegueWithIdentifier:@"go2FileDownloadSegue" sender:nil];
    });
#else
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSIndexPath *ip in _selCellsTable.selectedCells) {
            ICatchFile f = _curFileTable.fileList.at(ip.row);
            NSString *uid = _shCamObj.camera.cameraUid;
            SHFile *file = [SHFile fileWithUid:uid file:f];
            [[SHDownloadManager shareDownloadManger] addDownloadFile:file];
        }
        
        [[SHDownloadManager shareDownloadManger] startDownloadFile];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self performSegueWithIdentifier:@"go2FileDownloadSegue" sender:nil];
            [self clearSelectedCellTable];
            [self editAction:nil];
        });
    });
#endif
}

- (NSArray *)downloadSelectedFiles
{
    SHLogTRACE();
    NSInteger downloadedPhotoNum = 0, downloadedVideoNum = 0;
    NSInteger downloadFailedCount = 0;
    
    for (NSIndexPath *ip in _selCellsTable.selectedCells) {
        if (_cancelDownload) break;
        
        ICatchFile f = _curFileTable.fileList.at(ip.row);
        
        self.downloadFileProcessing = YES;
        self.downloadedPercent = 0;//Before the download clear downloadedPercent and increase downloadedFileNumber.
        //        self.downloadedFileNumber = [_ctrl.fileCtrl retrieveDownloadedTotalNumber];
        self.downloadedFileNumber ++;
        [self requestDownloadPercent:&f];
        if (![_ctrl.fileCtrl downloadFile:&f]) {
            ++downloadFailedCount;
            self.downloadFileProcessing = NO;
            continue;
        }
        
        self.downloadFileProcessing = NO;
        [NSThread sleepForTimeInterval:0.5];
        
        //[self.shareFiles addObject:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithUTF8String:f.getFileName().c_str()]]]];
    }
    
    return [NSArray arrayWithObjects:@(downloadedPhotoNum), @(downloadedVideoNum), @(downloadFailedCount), nil];
}

- (void)requestDownloadPercent:(ICatchFile *)file
{
    SHLogTRACE();
    if (!file) {
        SHLogError(SHLogTagAPP, @"file is null");
        return;
    }
    
    ICatchFile *f = file;
    NSString *locatePath = nil;
    NSString *fileName = [NSString stringWithUTF8String:f->getFileName().c_str()];
    unsigned long long fileSize = f->getFileSize();
    //locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    NSString *fileDirectory = nil;
    if (f->getFileType() == ICH_FILE_TYPE_VIDEO /*[fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]*/) {
        fileDirectory = [SHTool createMediaDirectoryWithPath:_shCamObj.camera.cameraUid.md5][2];
    } else {
        fileDirectory = [SHTool createMediaDirectoryWithPath:_shCamObj.camera.cameraUid.md5][1];
    }
    locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
    
    SHLogInfo(SHLogTagAPP, @"locatePath: %@, %llu", locatePath, fileSize);
    
    dispatch_async(self.downloadPercentQueue, ^{
        do {
            @autoreleasepool {
                if (_cancelDownload) break;
                //self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent:f];
                self.downloadedPercent = [_ctrl.fileCtrl requestDownloadedPercent2:locatePath
                                                                          fileSize:fileSize];
                SHLogInfo(SHLogTagAPP, @"percent: %lu", (unsigned long)self.downloadedPercent);
                
                [NSThread sleepForTimeInterval:0.2];
            }
        } while (_downloadFileProcessing);
        
    });
}

#pragma mark - selectedOperate
//全选
- (IBAction)selectedAction:(id)sender {
    SHLogTRACE();
    
    if (self.selCellsTable.count) {
        //cancel select
        [_selCellsTable.selectedCells removeAllObjects];
        self.selCellsTable.count = 0;
        self.totalDownloadSize = 0;
    } else {
        for (int i = 0; i < _curFileTable.fileList.size(); i++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_selCellsTable.selectedCells addObject:indexPath];
            
            ICatchFile file = _curFileTable.fileList.at(i);
            _totalDownloadSize += file.getFileSize()>>10;
        }
        self.selCellsTable.count = _selCellsTable.selectedCells.count;
    }
    
    [self.tableView reloadData];
    [self updateSelectStatus];
}

- (void)updateSelectStatus {
    if (self.selCellsTable.count) {
        [self.selectedButton setImage:[UIImage imageNamed:@"ic_select_all_white_24dp"] forState:UIControlStateNormal];
    } else {
        [self.selectedButton setImage:[UIImage imageNamed:@"ic_unselected_white_24dp"] forState:UIControlStateNormal];
    }
    
    [self.selectedNumber setTitle:[NSString stringWithFormat:@"%zd/%zd", self.selCellsTable.count, _curFileTable.fileList.size()] forState:UIControlStateNormal];
}

- (void)selectedNumberAction:(UIBarButtonItem *)sender {
    SHLogTRACE();
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
    return CGRectIntegral(CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height));
}

#pragma mark - goHomeOperate
- (IBAction)goHome:(id)sender {
    self.run = NO;
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            
            [self dismissViewControllerAnimated:YES completion:^{
                SHLogInfo(SHLogTagAPP, @"QUIT -- SHMpb");
            }];
        });
    });
}

#pragma mark - editOperate
//进入编辑模式
- (IBAction)editAction:(id)sender {
    SHLogTRACE();
    
    if (_curMpbState == SHMpbStateNor) {
        self.title = NSLocalizedString(@"SelectItem", nil);
        self.curMpbState = SHMpbStateEdit;
        self.editButton.title = NSLocalizedString(@"Cancel", @"");
        self.editButton.style = UIBarButtonItemStyleDone;
        
        self.doneButton.enabled = NO;
        self.showFilterButton.enabled = NO;
        self.showDownloadButton.enabled = NO;
        
        self.footerView.alpha = 0.85;
        
        //        [self.selCellsTable addObserver:self forKeyPath:@"count" options:0x0 context:nil];
        [self updateSelectStatus];
    } else {
        self.title = NSLocalizedString(@"Albums", @"");
        self.curMpbState = SHMpbStateNor;
        self.editButton.title = NSLocalizedString(@"Edit", @"");
        
        self.doneButton.enabled = YES;
        self.showFilterButton.enabled = YES;
        self.showDownloadButton.enabled = YES;
        
        self.footerView.alpha = 0;
        
        // Clear
        [self clearSelectedCellTable];
        
        //        [self.selCellsTable removeObserver:self forKeyPath:@"count"];
    }
}

//筛选过滤条件
- (IBAction)showFilterAction:(id)sender {
    SHLogTRACE();
    
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        //此处标题不正确，ALERT_TITLE_SET_SELF_TIMER，需要添加新的title
        self.filterView = [[CustomIOS7AlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_SET_FILTER", nil) inView:self.view];
        self.filterView.delegate = self;
        UIView      *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
        UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                              style:UITableViewStyleGrouped];
        [containerView addSubview:tableView];
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.filterTableView = tableView;
        
        _filterView.containerView = containerView;
        [_filterView setUseMotionEffects:TRUE];
        //    [NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]
        [_filterView setButtonTitles:@[NSLocalizedString(@"ALERT_CLOSE", @""), NSLocalizedString(@"SavePhoto", nil)]];
        
        __weak SHMpbTVC *weakSelf = self;
        [_filterView setCloseComplete:^{
            weakSelf.filterView = nil;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            [_filterView show];
        });
    });
}

- (IBAction)showDownloadAction:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
//        self.readyGoToFileDownloadVC = YES;
        [self performSegueWithIdentifier:@"go2FileDownloadSegue" sender:nil];
    });
}

- (IBAction)calendarAction:(id)sender {
    if (_calendar.frame.origin.y != [UIScreen screenHeight] && _calendar) {
        [_calendar dismiss];
    } else {
        [_calendar show];
    }
}

- (IBAction)changeDateAction:(UIButton *)sender {
    NSString *curDay = sender.currentTitle;
    
    if ([curDay isEqualToString:[_latestFileDate substringFromIndex:8]]) {
        UIView *iconView = [self.view viewWithTag:kNewFileIconTag];
        if (iconView) {
            [UIView animateWithDuration:0.25 animations:^{
                iconView.alpha = 0;
            } completion:^(BOOL finished) {
                [iconView removeFromSuperview];
            }];
            [self updateCameraFileList];
            
            return;
        }
    }
    
    [self.storageInfoArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHFileTable *table = obj;
        if ([curDay isEqualToString:[table.fileCreateDate substringFromIndex:8]]) {
            _curFileTable = table;
            *stop = YES;
            
            [self updateButtonBackgroundColor:table.fileCreateDate];
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - HWCalendarDelegate
- (void)calendar:(HWCalendar *)calendar didClickSureButtonWithDate:(NSString *)date
{
    SHLogInfo(SHLogTagAPP, @"selected date: %@", date);
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm"];
    NSDate *curDate = [dateformatter dateFromString:date];
    if ([self isCurrentDate:curDate]) {
        return;
    }
    
    [self updateShowDate:curDate];
    self.curDate = [curDate convertToStringWithFormat:kDateFormat];//[SHGUIHandleTool dateToString:curDate andFormat:kDateFormat];
    
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
    [_shCamObj.gallery resetPhotoGalleryDataWithStartDate:self.curDate endDate:nil judge:NO completeBlock:^(id obj) {
        self.storageInfoArray = obj;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            [self initMpbGUI];
            [self updateMpbGUI];
        });
    }];
}

- (BOOL)isCurrentDate:(NSDate *)newDate {
    NSString *tempDate = [newDate convertToStringWithFormat:kDateFormat];//[SHGUIHandleTool dateToString:newDate andFormat:kDateFormat];
    NSArray *tempDateArray = [tempDate componentsSeparatedByString:@" "];
    NSArray *curDateArray = [self.curDate componentsSeparatedByString:@" "];
    
    return [tempDateArray.firstObject isEqualToString:curDateArray.firstObject];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.filterView) {
        return self.filterArray.count;
    } else {
        if(_curFileTable.fileList.size() == 0){
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }else{
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.filterView) {
        return [self getFilterItemsWithSection:section].count;
    } else {
        return _curFileTable.fileList.size();
    }
}

- (NSArray *)getFilterItemsWithSection:(NSInteger)section {
    NSDictionary *group = self.filterArray[section];
    NSArray *items = nil;
    
    switch (section) {
        case SHFileFilterMonitorType:
            items = group[@"SHFileFilterMonitorType"];
            break;
            
        case SHFileFilterFileType:
            items = group[@"SHFileFilterFileType"];
            break;
            
        case SHFileFilterFavoriteType:
            items = group[@"SHFileFilterFavoriteType"];
            break;
            
        default:
            break;
    }
    
    return items;
}

- (NSDictionary *)getFilterItemWithIndexPath:(NSIndexPath *)indexPath {
    return [self getFilterItemsWithSection:indexPath.section][indexPath.row];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.filterView) {
        SHMpbTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SHMpbCellID" forIndexPath:indexPath];
        
        [self setCellTag:cell indexPath:indexPath];
        
        ICatchFile file = _curFileTable.fileList.at(indexPath.row);
        // Configure the cell...
        cell.file = &file;
        cell.cameraNameLabel.text = _shCamObj.camera.cameraName;
        
        UIImage *image = [self getFileThumbnail:file];
        [cell.fileThumbs layoutIfNeeded];
        if (image) {
            cell.fileThumbs.image = [image ic_cornerImageWithSize:cell.fileThumbs.bounds.size radius:kImageCornerRadius];
        } else {
            cell.fileThumbs.image = [[UIImage imageNamed:@"empty_photo"] ic_cornerImageWithSize:cell.fileThumbs.bounds.size radius:kImageCornerRadius];
            double delayInSeconds = 0.05;
            dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(delayTime, self.thumbnailQueue, ^{
                if (!_run) {
                    SHLogInfo(SHLogTagAPP, @"bypass...");
                    return;
                }
                
                dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
                dispatch_semaphore_wait(self.mpbSemaphore, time);
                // Just in case, make sure the cell for this indexPath is still On-Screen.
                __block UITableViewCell *tempCell = nil;
                dispatch_sync(dispatch_get_main_queue(), ^{
                    tempCell = [tableView cellForRowAtIndexPath:indexPath];
                });
                
                if (tempCell) {
                    NSData *imageData = [_ctrl.propCtrl requestThumbnail:(ICatchFile *)&file andPropertyID:TRANS_PROP_GET_FILE_THUMBNAIL andCamera:_shCamObj];
                    
                    //                    UIImage *image = [_ctrl.fileCtrl requestThumbnail:(ICatchFile *)&file];
                    UIImage *image = [UIImage imageWithData:imageData];
                    if (image) {
                        SHFileThumbnail *thumbFile = [SHFileThumbnail fileThumbnailWithFile:(ICatchFile *)&file andThumbnailData:imageData];
                        
                        [self.db insertToDataBaseWithFileThumbnail:thumbFile];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            //                            [self.mpbCache setObject:image forKey:cachedKey];
                            SHMpbTableViewCell *c = (SHMpbTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                            if (c) {
                                c.fileThumbs.image = [image ic_cornerImageWithSize:cell.fileThumbs.bounds.size radius:kImageCornerRadius];//image;
                            }
                        });
                    } else {
                        SHLogError(SHLogTagAPP, @"request thumbnail failed");
                    }
                }
                
                dispatch_semaphore_signal(self.mpbSemaphore);
            });
        }
        
        //        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else {
        SHFilterTableViewCell *cell = [[SHFilterTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                                   reuseIdentifier:nil withSelectedImage:nil withUnSelectedImage:nil];
        
        cell.item = [self getFilterItemWithIndexPath:indexPath];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
    }
}

- (UIImage *)getFileThumbnail:(ICatchFile)file {
    //    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
    //    UIImage *image = [self.mpbCache objectForKey:cachedKey];
    UIImage *image = nil;
    
    NSArray *fileThumbArray = [self.db queryFromDataBaseWithFileHandle:file.getFileHandle()];
    if (fileThumbArray && fileThumbArray.count) {
        SHFileThumbnail *thumbFile = fileThumbArray.firstObject;
        image = [UIImage imageWithData:thumbFile.thumbnail];
    }
    
    return image;
}

- (void)getFileThumbnail:(ICatchFile *)file andTableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    double delayInSeconds = 0.05;
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(delayTime, self.thumbnailQueue, ^{
        if (!_run) {
            SHLogInfo(SHLogTagAPP, @"bypass...");
            return;
        }
       
        dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
        dispatch_semaphore_wait(self.mpbSemaphore, time);
        // Just in case, make sure the cell for this indexPath is still On-Screen.
        if ([tableView cellForRowAtIndexPath:indexPath]) {
            NSData *imageData = [_ctrl.propCtrl requestThumbnail:file andPropertyID:TRANS_PROP_GET_FILE_THUMBNAIL andCamera:_shCamObj];
            
            //            UIImage *image = [_ctrl.fileCtrl requestThumbnail:(ICatchFile *)&file];
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                SHFileThumbnail *thumbFile = [SHFileThumbnail fileThumbnailWithFile:(ICatchFile *)&file andThumbnailData:imageData];
                
                [self.db insertToDataBaseWithFileThumbnail:thumbFile];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    //                    [self.mpbCache setObject:image forKey:cachedKey];
                    SHMpbTableViewCell *c = (SHMpbTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                    if (c) {
                        c.fileThumbs.image = image;
                    }
                });
            } else {
                SHLogError(SHLogTagAPP, @"request thumbnail failed");
            }
        }
        
        dispatch_semaphore_signal(self.mpbSemaphore);
    });
}
//选中和未选中状态
- (void)setCellTag:(SHMpbTableViewCell *)cell
         indexPath:(NSIndexPath *)indexPath {
    if ([_selCellsTable.selectedCells containsObject:indexPath]) {
        [cell setSelectedConfirmIconHidden:NO];
        cell.tag = 1;
    } else {
        [cell setSelectedConfirmIconHidden:YES];
        cell.tag = 0;
    }
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *cellTitle = nil;
    
    if (self.filterView) {
        switch (section) {
            case SHFileFilterMonitorType:
                cellTitle = NSLocalizedString(@"kMonitoringType", nil);
                break;
                
            case SHFileFilterFileType:
                cellTitle = NSLocalizedString(@"kFileType", nil);
                break;
                
            case SHFileFilterFavoriteType:
                cellTitle = NSLocalizedString(@"kCollection", nil);
                break;
                
            default:
                break;
        }
    }
    
    return cellTitle;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.filterView) {
        ICatchFile file = _curFileTable.fileList.at(indexPath.row);
        
        //执行跳转到视频播放或者图片预览
        if (_curMpbState == SHMpbStateNor) {
            SEL callback = nil;
            
            switch (file.getFileType()) {
                case ICH_FILE_TYPE_IMAGE:
                    callback = @selector(photoSinglePlaybackCallback:);
                    break;
                    
                case ICH_FILE_TYPE_VIDEO:
                    callback = @selector(videoSinglePlaybackCallback:);
                    break;
                    
                default:
                    break;
            }
            
            if (callback && [self respondsToSelector:callback]) {
                SHLogInfo(SHLogTagAPP, @"callback-index: %ld", (long)indexPath.row);
                [self performSelector:callback withObject:indexPath afterDelay:0];
            } else {
                SHLogInfo(SHLogTagAPP, @"It's not support to playback this file.");
            }
        } else {
            SHMpbTableViewCell *cell = (SHMpbTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
            if (cell.tag == 1) { // It's selected.
                cell.tag = 0;
                [cell setSelectedConfirmIconHidden:YES];
                [_selCellsTable.selectedCells removeObject:indexPath];
                _totalDownloadSize -= file.getFileSize()>>10;
            } else {
                cell.tag = 1;
                [cell setSelectedConfirmIconHidden:NO];
                [_selCellsTable.selectedCells addObject:indexPath];
                _totalDownloadSize += file.getFileSize()>>10;
            }
            
            self.selCellsTable.count = _selCellsTable.selectedCells.count;
            [self updateSelectStatus];
        }
    } else {
        SHFilterTableViewCell *cell = (SHFilterTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        
        NSDictionary *item = [self getFilterItemWithIndexPath:indexPath];
        NSString *identifier = item[@"Identifier"];
        
        if (cell.tag) {
            [cell setSelectedStatus:NO];
            if (identifier) {
                [self.selectedFilterCells addObject:identifier];
            }
        } else {
            [cell setSelectedStatus:YES];
            if (identifier) {
                [self.selectedFilterCells addObject:identifier];
            }
        }
    }
}

- (CGFloat)calcRowHeight {
    CGFloat screenW = [UIScreen screenWidth];
    NSInteger space = 4;
    
    CGFloat imgViewW = screenW  * 0.4;
    CGFloat imgViewH = imgViewW * 9 / 16;
    
    CGFloat rowH = imgViewH + space * 2;
    
    //    NSLog(@"height: %f", rowH);
    return rowH;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.filterView) {
        return 44.0;
    } else {
        return [self calcRowHeight];
    }
}

- (void)photoSinglePlaybackCallback:(NSIndexPath *)indexPath {
}

- (void)videoSinglePlaybackCallback:(NSIndexPath *)indexPath
{
    SHLogTRACE();
    //    if (![_ctrl.pbCtrl videoPlaybackStreamEnabled]) {
    //        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"ShowNoViewVideoTip", nil) showTime:1.0];
    //        return;
    //    }
    
    ICatchFile file = _curFileTable.fileList.at(indexPath.row);
    
    //    NSString *cachedKey = [NSString stringWithFormat:@"ID%d", file.getFileHandle()];
    _videoPlaybackIndex = indexPath.row;
    
    //    UIImage *image = [self.mpbCache objectForKey:cachedKey];
    UIImage *image = [self getFileThumbnail:file];
    if (!image) {
        dispatch_suspend(self.thumbnailQueue);
        
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)
                                      detailsMessage:nil
                                                mode:MBProgressHUDModeIndeterminate];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (!_run) {
                return;
            }
            
            dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
            dispatch_semaphore_wait(_mpbSemaphore, time);
            
            //            UIImage *image = [_ctrl.fileCtrl requestThumbnail:(ICatchFile *)&file];
            //            if (image != nil) {
            //                [_mpbCache setObject:image forKey:cachedKey];
            //            }
            NSData *imageData = [_ctrl.propCtrl requestThumbnail:(ICatchFile *)&file andPropertyID:TRANS_PROP_GET_FILE_THUMBNAIL andCamera:_shCamObj];
            
            UIImage *image = [UIImage imageWithData:imageData];
            if (image) {
                SHFileThumbnail *thumbFile = [SHFileThumbnail fileThumbnailWithFile:(ICatchFile *)&file andThumbnailData:imageData];
                
                [self.db insertToDataBaseWithFileThumbnail:thumbFile];
            }
            
            dispatch_semaphore_signal(_mpbSemaphore);
            dispatch_resume(self.thumbnailQueue);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _videoPlaybackThumb = image;
                [self performSegueWithIdentifier:@"go2PlaybackVideoSegue" sender:nil];
            });
        });
    } else {
        _videoPlaybackThumb = image;
        [self performSegueWithIdentifier:@"go2PlaybackVideoSegue" sender:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    SHLogTRACE();
    if ([[segue identifier] isEqualToString:@"go2PlaybackVideoSegue"]) {
        UINavigationController *navVC = [segue destinationViewController];
        SHVideoPlaybackVC *vpvc = (SHVideoPlaybackVC *)navVC.topViewController;
        vpvc.delegate = self;
        vpvc.previewImage = _videoPlaybackThumb;
        vpvc.index = _videoPlaybackIndex;
        vpvc.curFileTable = _curFileTable;
        vpvc.cameraUid = _cameraUid;
    } else if ([segue.identifier isEqualToString:@"go2FileDownloadSegue"]) {
        SHFileDownloadTVC *vc = segue.destinationViewController;
        vc.cameraUid = _shCamObj.camera.cameraUid;
        //vc.downloadArray = [NSMutableArray arrayWithArray:[SHDownloadManager shareDownloadManger].downloadArray];
//        [vc setDownloadCompleteBlock:^ {
//            _isDownloading = NO;
//            _totalDownloadSize = 0;
//        }];
    }
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        UIView *v = self.view.window;
        if (v == nil) {
            v = self.view;
        }
        
        _progressHUD = [MBProgressHUD progressHUDWithView:v];
    }
    
    return _progressHUD;
}

- (MBProgressHUD *)progressHUDFilter {
    //    if (!_progressHUDFilter) {
    //        _progressHUDFilter = [MBProgressHUD progressHUDWithView:self.filterTableView.window];
    //    }
    
    return [MBProgressHUD progressHUDWithView:self.filterTableView.window];
}

- (void)prepareForAction {
    
}

- (void)prepareForCancelAction
{
    SHLogTRACE();
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject              :(id)object
        change                :(NSDictionary *)change
        context               :(void *)context
{
    SHLogTRACE();
    if ([keyPath isEqualToString:@"count"]) {
        if (_selCellsTable.count > 0) {
            [self prepareForAction];
        } else {
            [self prepareForCancelAction];
        }
    } else if ([keyPath isEqualToString:@"downloadedFileNumber"]) {
        NSUInteger handledNum = MIN(_downloadedFileNumber, _totalDownloadFileNumber);
        NSString *msg = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)handledNum, (unsigned long)_totalDownloadFileNumber];
        [self.progressHUD updateProgressHUDWithMessage:msg detailsMessage:nil percent:0];
    } else if([keyPath isEqualToString:@"downloadedPercent"]) {
        NSString *msg = [NSString stringWithFormat:@"%lu%%", (unsigned long)_downloadedPercent];
        if (self.downloadedFileNumber) {
            [self.progressHUD updateProgressHUDWithMessage:nil detailsMessage:msg percent:_downloadedPercent];
        }
    }
}

#pragma mark - VideoPlaybackControllerDelegate
- (BOOL)videoPlaybackController:(SHVideoPlaybackVC *)controller
             deleteVideoAtIndex:(NSUInteger)index
{
    SHLogTRACE();
    return [self delectFileAtIndex:index];
}

#pragma mark - CustomIOS7AlertViewDelegate
- (void)customIOS7dialogButtonTouchUpInside:(id)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (!buttonIndex) {
    } else {
        //        dispatch_queue_t setFileFilterQ = dispatch_queue_create("WifiCam.GCD.Queue.SetFileFilter", DISPATCH_QUEUE_SERIAL);
        
        //        dispatch_sync(setFileFilterQ, ^{
        [self setSelectedFileFilter];
        
        int retVal = [_shCamObj.controler.fileCtrl setFilesFilter:self.filterArray];
        
        if (retVal < 0) {
            [self setSelectedFileFilter];
            
            [self.progressHUDFilter showProgressHUDNotice:NSLocalizedString(@"kFilterSelectedFailed", nil) showTime:2.0];
            return;
        } else if (retVal == NO) {
            [self setSelectedFileFilter];
            
            [self.progressHUDFilter showProgressHUDNotice:NSLocalizedString(@"kSetFilterFailed", nil) showTime:2.0];
            return;
        } else {
            [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
            [_shCamObj.gallery resetPhotoGalleryDataWithStartDate:self.curDate endDate:nil judge:NO completeBlock:^(id obj) {
                self.storageInfoArray = obj;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hide:YES];
                    [self initMpbGUI];
                    [self updateMpbGUI];
                });
            }];
        }
        //        });
    }
    
    [self.selectedFilterCells removeAllObjects];
    [self.filterView close];
}

- (void)setSelectedFileFilter {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (NSString *key in self.selectedFilterCells) {
        if ([defaults boolForKey:key]) {
            [defaults setBool:NO forKey:key];
        } else {
            [defaults setBool:YES forKey:key];
        }
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self delectFileAtIndex:indexPath.row];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
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

#pragma mark - NewFileHandle
- (void)addNewFileIcon:(UIButton *)btn {
    UIView *iconView = [self.view viewWithTag:kNewFileIconTag];
    if (iconView) {
        return;
    }
    
    CGRect iconRect = CGRectMake(CGRectGetMaxX(btn.superview.frame) - kButtonRadius * 0.8, btn.superview.frame.origin.y + kButtonRadius * 0.6, kNewFileIconWidth, kNewFileIconWidth);
    UIView *icon = [[UIView alloc] initWithFrame:iconRect];
    
    icon.backgroundColor = [UIColor redColor];
    icon.layer.cornerRadius = kNewFileIconWidth * 0.5;
    icon.tag = kNewFileIconTag;
    
    [self.view addSubview:icon];
}

- (void)addCameraPropertyValueChangeBlock {
    WEAK_SELF(self);
    
    [_shCamObj setCameraPropertyValueChangeBlock:^ (SHICatchEvent *evt) {
        switch (evt.eventID) {
            case ICATCH_EVENT_FILE_ADDED:
                SHLogInfo(SHLogTagAPP, @"receive ICATCH_EVENT_FILE_ADDED");
                [weakself.shCamObj.gallery cleanDateInfo];
                [weakself.shCamObj.cameraProperty updateSDCardInfo:weakself.shCamObj];
                [weakself newFileEventHandler:evt];
                break;

            default:
                break;
        }
    }];
}

- (void)newFileEventHandler:(SHICatchEvent *)evt {
    ICatchFile newFile = evt.fileValue;
    _latestFileDate = [NSString stringWithFormat:@"%s", newFile.getFileDate().c_str()];
    
//    if ([_latestFileDate isEqualToString:_curFileTable.fileCreateDate]) {
//        [self updateCameraFileList];
//    } else {
//        [self updateDateViewGUI];
//    }
    [self updateDateViewGUI];
}

- (void)updateDateViewGUI {
    NSString *day = [_latestFileDate substringFromIndex:8];
    int temp = [day intValue];
    
    __block UIButton *btn = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (temp == [self getButtonTitle:_firstButton]) {
            btn = _firstButton;
        } else if (temp == [self getButtonTitle:_secondButton]) {
            btn = _secondButton;
        } else if (temp == [self getButtonTitle:_thirdButton]) {
            btn = _thirdButton;
        } else if (temp == [self getButtonTitle:_fourthButton]) {
            btn = _fourthButton;
        } else if (temp == [self getButtonTitle:_fifthButton]) {
            btn = _fifthButton;
        } else if (temp == [self getButtonTitle:_sixthButton]) {
            btn = _sixthButton;
        } else if (temp == [self getButtonTitle:_seventhButton]) {
            btn = _seventhButton;
        } else if (temp == [self getButtonTitle:_eighthButton]) {
            btn = _eighthButton;
        }
        
        if (btn) {
            [self addNewFileIcon:btn];
        }
    });
}

- (void)updateCameraFileList {
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
    
    [_shCamObj.gallery resetPhotoGalleryDataWithStartDate:[_latestFileDate stringByAppendingString:@" 00:00:00"] endDate:nil judge:YES completeBlock:^(id obj) {
        self.storageInfoArray = obj;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hide:YES];
            [self initMpbGUI];
            [self updateMpbGUI];
        });
    }];
}

@end
