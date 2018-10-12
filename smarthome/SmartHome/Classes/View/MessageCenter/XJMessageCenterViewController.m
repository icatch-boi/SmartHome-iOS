// XJMessageCenterViewController.m

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
 
 // Created by sa on 2018/5/28 上午9:13.
    

#import "XJMessageCenterViewController.h"
#import "XJMessageTitleTableViewCell.h"
#import "XJMessageDetailTableViewCell.h"
#import "MessageCenter.h"
//#import "SHFileOperation.h"
#import "MessageDetailInfo.h"
#import "SHVideoPlaybackVC.h"
#import "ICatchFile.h"
#import "SHFileTable.h"
#import "TimeHelper.h"
#import "SHCameraManager.h"
#import "MSGNetWorkProtocol.h"
#import "SHUtilsMacro.h"
static const int reconnectCnt = 1;
#define UIColorFromHex(c) ([UIColor colorWithRed:((c&0xff0000)>>16)/255.0 green:((c&0x00ff00)>>8)/255.0 blue:(c&0xff)/255.0 alpha:1.0])

static NSString * const allBtnBlueImg = @"message center-btn-all_1";
static NSString * const allBtnWhiteImg = @"message center-btn-all-pre_1";
static NSString * const pirBtnBlueImg = @"message center-btn-action detection_1";
static NSString * const pirBtnWhiteImg = @"message center-btn-action detection-pre_1";
static NSString * const ringBtnBlueImg = @"message center-btn-ring_1";
static NSString * const ringBtnWhiteImg = @"message center-btn-ring-pre_1";
@interface XJMessageCenterViewController () <UITableViewDataSource, UITableViewDelegate, DataSourceProtocol, MSGNetWorkProtocol>
@property (weak, nonatomic) IBOutlet UITableView *detailTableView;
@property (weak, nonatomic) IBOutlet UIButton *allBtn;
@property (weak, nonatomic) IBOutlet UIButton *ringBtn;
@property (weak, nonatomic) IBOutlet UIButton *pirBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *selectAllBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;

@property (weak, nonatomic) IBOutlet UIView *bottomView;

@property (nonatomic) NSInteger messageType;
@property (nonatomic, strong) MessageCenter *msgCenter;
@property (nonatomic, strong) NSMutableArray *msgInfoAll;
@property (nonatomic, strong) NSMutableArray *msgInfoPir;
@property (nonatomic, strong) NSMutableArray *msgInfoRing;
@property (nonatomic, strong) NSMutableArray *deleteStore;

@property (nonatomic) dispatch_queue_t fileInfoQueue;
@property (nonatomic) dispatch_semaphore_t sourceSem;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic) int connectCnt;

@property (nonatomic) BOOL editing;
@property (nonatomic) BOOL allSelected;
@end

@implementation XJMessageCenterViewController

- (void)changBtnSelectedStatus {
    

    UIColor *XJBlueColor = UIColorFromHex(0x076ee4);
    
    UIColor *XJLowGrayColor = UIColorFromHex(0xe8e8e8);
    switch (self.messageType) {
            
        case MessageTypeRing:
            self.ringBtn.backgroundColor = XJBlueColor;
            self.ringBtn.selected = YES;
            
            self.allBtn.backgroundColor = XJLowGrayColor;
            self.allBtn.selected = NO;
            self.pirBtn.backgroundColor = XJLowGrayColor;
            self.pirBtn.selected = NO;
            break;
            
        case MessageTypePir:
            self.pirBtn.backgroundColor = XJBlueColor;
            self.pirBtn.selected = YES;
            
            self.allBtn.backgroundColor = XJLowGrayColor;
            self.allBtn.selected = NO;
            self.ringBtn.backgroundColor = XJLowGrayColor;
            self.ringBtn.selected = NO;
            break;
            
        default:
            self.allBtn.backgroundColor = XJBlueColor;
            self.allBtn.selected = YES;
            
            self.pirBtn.backgroundColor = XJLowGrayColor;
            self.pirBtn.selected = NO;
            self.ringBtn.backgroundColor = XJLowGrayColor;
            self.ringBtn.selected = NO;
            break;
    }
}

#pragma mark - button action
- (IBAction)allBtn:(UIButton *)sender {
    if(self.messageType ==  MessageTypeAll) {
        return;
    }
    if(self.editing) {
        [self resetEditStatus];
    }
    self.messageType = MessageTypeAll;
    [self changBtnSelectedStatus];
    [self.detailTableView reloadData];
}

- (IBAction)ringBtn:(UIButton *)sender {
    if(self.messageType ==  MessageTypeRing) {
        return;
    }
    if(self.editing) {
        [self resetEditStatus];
    }
    self.messageType = MessageTypeRing;
    [self changBtnSelectedStatus];
    [self.detailTableView reloadData];
}

- (IBAction)pirBtn:(UIButton *)sender {
    if(self.messageType ==  MessageTypePir) {
        return;
    }
    if(self.editing) {
        [self resetEditStatus];
    }
    self.messageType = MessageTypePir;
    [self changBtnSelectedStatus];
    [self.detailTableView reloadData];
}
-(void)resetEditStatus {
    if(self.editing) {
        self.bottomView.hidden = YES;
        self.cancelBtn.hidden = YES;
        //self.detailTableView.allowsSelectionDuringEditing = NO;
        self.detailTableView.editing = NO;
        if(self.deleteStore.count) {
            [self.deleteStore removeAllObjects];
        }
        self.editing = NO;
    }
}

- (IBAction)selectAllBtn:(UIButton *)sender {

    if(self.deleteStore.count > 0) {
        [self.deleteStore removeAllObjects];
    }
    self.allSelected = !self.allSelected;
    NSArray *tmpArr = nil;
    if(self.messageType == MessageTypeAll) {
        tmpArr = self.msgInfoAll;
    } else if (self.messageType == MessageTypePir) {
        tmpArr = self.msgInfoPir;
    } else {
        tmpArr = self.msgInfoRing;
    }
    for (int i = 0; i < tmpArr.count; i++) {
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        if (self.allSelected == NO) {
            [self.detailTableView deselectRowAtIndexPath:indexPath animated:YES];
        } else {
            [self.detailTableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
        }
    }
    if (self.allSelected == YES) {
        [self.deleteStore addObjectsFromArray:tmpArr];
        [self.selectAllBtn setTitle:@"Unselect All" forState:UIControlStateNormal];
    } else {
         [self.selectAllBtn setTitle:@"Select All" forState:UIControlStateNormal];
    }

}


- (IBAction)deleteBtn:(UIButton *)sender {
    NSLog(@"select count : %d", self.deleteStore.count);
    
    NSString *errorInfo = [NSString stringWithFormat:@"确认删除选中的消息吗？"];
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.msgInfoAll removeObjectsInArray:self.deleteStore];
        dispatch_async(self.fileInfoQueue, ^{
            for(MessageDetailInfo *info in self.deleteStore) {
                [self.msgCenter deleteMessageWithMessageInfo:info.msgInfo];
            }
            NSLog(@"%@", self.deleteStore);
            [self.deleteStore removeAllObjects];
        });
        
        //从all 中移除 deletestore
        
        //刷新 pir 及 ring
        [self.msgInfoPir removeAllObjects];
        [self.msgInfoRing removeAllObjects];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.detailTableView reloadData];
        });
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUD hideProgressHUD:YES];
            
        });
    }]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"用户取消删除选中的信息");
    }]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertC animated:YES completion:nil];
    });
    
}
- (IBAction)cancelBtn:(UIButton *)sender {
    //将状态还原
    [self resetEditStatus];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.detailTableView registerNib:[UINib nibWithNibName:@"XJMessageDetailTableViewCell" bundle:nil] forCellReuseIdentifier:detailCellID];
    self.detailTableView.delegate = self;
    self.detailTableView.dataSource = self;
    self.messageType = MessageTypeAll;
    self.msgCenter = [MessageCenter MessageCenterWithName:self.camUid andMsgDelegate:self];
    self.msgInfoAll = nil;
    self.msgInfoPir = nil;
    self.msgInfoRing = nil;
    self.editing = NO;
    [self changBtnSelectedStatus];
  
    self.sourceSem = dispatch_semaphore_create(1);
    _detailTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.connectCnt = 0;
    self.bottomView.hidden = YES;
    self.cancelBtn.hidden = YES;
    self.allSelected = NO;
    self.selectAllBtn.backgroundColor = UIColorFromHex(0xe8e8e8);
    self.deleteBtn.backgroundColor = UIColorFromHex(0xe8e8e8);
    [self setupGUI];
}

- (void)setupGUI {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil target:self action:@selector(close) isBack:YES];
}

- (void)close {
    [self.navigationController popViewControllerAnimated:YES];
    
    SHCameraManager *manager = [SHCameraManager sharedCameraManger];
    SHCameraObject *obj = [manager getSHCameraObjectWithCameraUid:_camUid];
    if (obj.isConnect) {
        [obj disConnectWithSuccessBlock:nil failedBlock:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated
{
    self.connectCnt = 0;
    [super viewWillDisappear:animated];
}
#pragma mark - 预加载
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        UIView *v = self.view;
        if (v == nil) {
            v = self.view;
        }
        _progressHUD = [MBProgressHUD progressHUDWithView:v];
    }
    return _progressHUD;
}

- (dispatch_queue_t)fileInfoQueue
{
    if(_fileInfoQueue == nil) {
        _fileInfoQueue = dispatch_queue_create("XJ.GCD.Queue.FileInfo.GetInfo", DISPATCH_QUEUE_SERIAL);
    }
    return _fileInfoQueue;
}

- (NSMutableArray *)deleteStore {
    if(_deleteStore == nil) {
        _deleteStore = [NSMutableArray new];
    }
    return _deleteStore;
}

- (NSArray *)msgInfoAll {
    if (dispatch_semaphore_wait(_sourceSem, 30 * NSEC_PER_MSEC) != 0) {
        NSLog(@"get null arr");
        return _msgInfoAll;
    }
    
    if(_msgInfoAll == nil) {
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
        dispatch_async(self.fileInfoQueue, ^{
            _msgInfoAll = [NSMutableArray new];
            int count = [self.msgCenter getMessageCount];
            
            NSArray * msgInfos = [self.msgCenter getMessageWithStartIndex:0 andCount:count];
            for(MessageInfo *msgInfo in msgInfos) {
                MessageDetailInfo *info = [MessageDetailInfo new];
                //MessageInfo *tmpInfo = [[MessageInfo alloc] initWithIndex:[msgInfo getMsgIndex] andMsgID:[msgInfo getMsgID] andDevID:[msgInfo getDevID] andDatetime:[msgInfo getMsgDatetime] andMsgType:[msgInfo getMsgType]];
                
                info.msgInfo = msgInfo;
                NSArray *fileInfos = [self.msgCenter getFileListWithMessageInfo:msgInfo];
                if(fileInfos.count) {
                    info.fileInfo = fileInfos[0];
                }
                [_msgInfoAll addObject:info];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self.detailTableView reloadData];
            });
           
            dispatch_semaphore_signal(_sourceSem);
        });
        
    } else {
        dispatch_semaphore_signal(_sourceSem);
    }
    return _msgInfoAll;
}

- (NSArray *)msgInfoPir {
    if(_msgInfoPir == nil || _msgInfoPir.count == 0) {
        if(_msgInfoPir == nil) {
            _msgInfoPir = [NSMutableArray new];
        }
        for (MessageDetailInfo *info in self.msgInfoAll) {
            if([info.msgInfo getMsgType] == MessageTypePir) {
                [_msgInfoPir addObject:info];
            }
        }
    }
    
    return _msgInfoPir;
}

- (NSArray *)msgInfoRing {
    if(_msgInfoRing == nil || _msgInfoRing.count == 0) {
        if(_msgInfoRing == nil) {
            _msgInfoRing = [NSMutableArray new];
        }
        for (MessageDetailInfo *info in self.msgInfoAll) {
            if([info.msgInfo getMsgType] == MessageTypeRing)    {
                [_msgInfoRing addObject:info];
            }
        }
    }
    return _msgInfoRing;
}

#pragma mark - datasource operation
-(void)removeMsgDetailInfo:(MessageDetailInfo *) info {
    for(MessageDetailInfo *tmpInfo in _msgInfoAll) {
        if([[tmpInfo.msgInfo getMsgDatetime] compare:[info.msgInfo getMsgDatetime]] == 0) {
            [_msgInfoAll removeObject:tmpInfo];
             NSLog(@"delete MessageTypeAll complete");
            break;
        }
    }
    if(self.messageType == MessageTypeRing) {
        for(MessageDetailInfo *tmpInfo in _msgInfoRing) {
            if([[tmpInfo.msgInfo getMsgDatetime] compare:[info.msgInfo getMsgDatetime]] == 0) {
                [_msgInfoRing removeObject:tmpInfo];
                NSLog(@"delete MessageTypeRing complete");
                break;
            }
        }
    }
    if(self.messageType == MessageTypePir) {
        for(MessageDetailInfo *tmpInfo in _msgInfoPir) {
            if([[tmpInfo.msgInfo getMsgDatetime] compare:[info.msgInfo getMsgDatetime]] == 0) {
                [_msgInfoPir removeObject:tmpInfo];
                NSLog(@"delete MessageTypePir complete");
                break;
            }
        }
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

#pragma mark - 长按手势
// 长按单元格事件
- (void)longPressGesture:(UIGestureRecognizer *)recongnizer
{
    if (recongnizer.state == UIGestureRecognizerStateBegan)
    {
        //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"删除联系人吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        //        [alert show];
        
        if(!self.editing) {
            self.detailTableView.allowsSelectionDuringEditing = YES;
            self.detailTableView.editing = YES;
            
            [self.bottomView setHidden:NO];
            [self.cancelBtn setHidden:NO];
            self.editing = YES;
        }
        
    }
}
#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    switch (self.messageType) {
        case MessageTypeRing:
            NSLog(@"ring cell count : %d", self.msgInfoRing.count);
            return self.msgInfoRing.count;
            
        case MessageTypePir:
            NSLog(@"pir cell count : %d", self.msgInfoPir.count);
            return self.msgInfoPir.count;
            
        default:
            NSLog(@"cell count : %d", self.msgInfoAll.count);
            return self.msgInfoAll.count;
    }
    
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(MessageDetailInfo *)getMessgeInfoWithIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"indexpath type %d - row = %d", self.messageType, indexPath.row);
    switch (self.messageType) {
        case MessageTypeRing:
            return self.msgInfoRing[indexPath.row];
            
        case MessageTypePir:
            return self.msgInfoPir[indexPath.row];
            
        default:
            return self.msgInfoAll[indexPath.row];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    XJMessageDetailTableViewCell *cell = [self.detailTableView dequeueReusableCellWithIdentifier:detailCellID];
    __block MessageDetailInfo *info = [self getMessgeInfoWithIndexPath:indexPath];
    cell.msgInfo = info.msgInfo;
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [cell addGestureRecognizer:longPressGesture];
    if(!self.editing) {
        dispatch_async(self.fileInfoQueue, ^{
            NSData * imgData = nil;
            if(!info.fileInfo){
                NSArray *fileInfos = [self.msgCenter getFileListWithMessageInfo:info.msgInfo];
                for(MsgFileInfo *fileInfo in fileInfos) {
                    info.fileInfo = fileInfo;
                    break;
                }
            }
            if(!info.fileInfo) {
                return ;
            }
            //[info.msgInfo debug];
            //[info.fileInfo debug];
            imgData = [self.msgCenter getThumbnailWithMsgFileInfo:info.fileInfo];
            if(imgData) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    XJMessageDetailTableViewCell *cell = (XJMessageDetailTableViewCell *)[self.detailTableView cellForRowAtIndexPath:indexPath];
                    if(cell) {
                        [cell.thumbnailImgView setImage:[UIImage imageWithData:imgData]];
                    }
                });
            }
        });
    }
  
    return cell;
}

#pragma mark - UITableViewDelegate
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageDetailInfo * detailInfo = [self getMessgeInfoWithIndexPath:indexPath];
    if(!self.editing) {
        [self.detailTableView deselectRowAtIndexPath:indexPath animated:YES];
        
        UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:kAlbumStoryboardName bundle:nil];
        UINavigationController *nav = [mainBoard instantiateViewControllerWithIdentifier:@"videoPlaybackView"];
        SHVideoPlaybackVC *videoPlayVC = (SHVideoPlaybackVC *)nav.topViewController;
        
        MsgFileInfo * info = detailInfo.fileInfo;
        if(!info) {
            NSString *errorInfo = [NSString stringWithFormat:@"没有视频文件哦"];
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
            
            WEAK_SELF(self);

            [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    
                });
            }]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertC animated:YES completion:nil];
            });
            return;
        }
        NSData *img = [_msgCenter getThumbnailWithMsgFileInfo:info];
        videoPlayVC.previewImage = [UIImage imageWithData:img];
        videoPlayVC.index = 0;
        videoPlayVC.cameraUid = self.camUid;
        
        //create SHFileTable
        ICatchFile file(info.handle, 0, info.duration, info.name.UTF8String, "", "", "", 0, ICH_FILE_TYPE_VIDEO,info.thumnailSize, NO);
        vector<ICatchFile> fileList;
        fileList.push_back(file);
        NSString *outterDate = [TimeHelper innerFormatToOutterFormat: info.datetime];
        NSDateFormatter *df = [NSDateFormatter new];
        [df setDateFormat:@"yyyy/MM/dd"];
        NSDate *date = [df dateFromString:outterDate];
        NSString *dateStr = [df stringFromDate:date];
        SHFileTable *table = [SHFileTable fileTableWithFileCreateDate:dateStr andFileStorage:0 andFileList:fileList];
        videoPlayVC.curFileTable = table;
        
        [self presentViewController:nav animated:YES completion:nil];
    } else {
//        XJMessageDetailTableViewCell *cell = [self.detailTableView dequeueReusableCellWithIdentifier:detailCellID forIndexPath:indexPath];
  
            [self.deleteStore addObject:detailInfo];
        
    }
}

-(void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageDetailInfo * info = [self getMessgeInfoWithIndexPath:indexPath];
    if(self.editing) {
        [self.deleteStore removeObject:info];
    }
}
#if 0
-(NSArray<UITableViewRowAction*> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *actionS = [NSMutableArray new];
#if 0 //是否加入删除单元格功能
    UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"delete" handler:^(UITableViewRowAction * _Nonnull action, NSIndexPath * _Nonnull indexPath) {
        MessageDetailInfo *info = [self getMessgeInfoWithIndexPath:indexPath];
        if(info.msgInfo) {
            NSLog(@"delete msginfo ...");
            [info.msgInfo debug];
            [self.msgCenter deleteMessageWithMessageInfo:info.msgInfo];
            [self removeMsgDetailInfo:info];
        }
        [self.detailTableView reloadData];
    }];
    deleteAction.backgroundColor = [UIColor redColor];
    [actionS addObject:deleteAction];
#endif
    return actionS;
}
#endif
#pragma mark - DataSourceProtocol
- (NSData *)getThumbnailWithMessageInfo:(MessageInfo *)msgInfo
{
    NSArray *fileInfos = [self.msgCenter getFileListWithMessageInfo:msgInfo];
    if(fileInfos.count) {
        NSData *data = [self.msgCenter getThumbnailWithMsgFileInfo:fileInfos[0]];
        return data;
    }
    return nil;
}

-(void)refreshUI {
    [self.detailTableView reloadData];
}

#pragma mark - MSGNetWorkProtocol
- (NSString*) getDateFromDatetime:(NSString*) datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [df dateFromString:datetime];
    [df setDateFormat:@"yyyy/MM/dd"];
    return [df stringFromDate:date];
}
-(SHCameraObject *) getCameraWithUUID:(NSString*) uuid
{
    //return nil;
    SHCameraManager *manager = [SHCameraManager sharedCameraManger];
    SHCameraObject* obj = [manager getSHCameraObjectWithCameraUid:uuid];
    if(obj == nil) {

        return nil;
    }
    
    if(![obj isConnect]) {
        if(self.connectCnt >= reconnectCnt) {
            return nil;
        }
        //连接相机失败，则返回空，什么都不做
        int ret = [obj connectCamera];
        if(ret != 0) {
            
            NSString *name = obj.camera.cameraName;
            NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(ret)];
            NSString *errorInfo = @"";
            errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
            errorInfo = [errorInfo stringByAppendingString:@"获取信息相关文件失败，请移驾到对应设备的相册中查看"];
            
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
            
            WEAK_SELF(self);
//            [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [weakself.progressHUD hideProgressHUD:YES];
//                    //[weakself setupUserInteractionState:NO];
//                });
//            }]];
            [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakself.progressHUD hideProgressHUD:YES];
                    [weakself close];
                });
            }]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:alertC animated:YES completion:nil];
            });
            self.connectCnt++;
            return nil;
        }
    }
    return obj;
}

- (NSData *)getThumbnailWithFileinfo:(MsgFileInfo *)info {
    NSData* data = nil;
    ICatchFile file(info.handle, 0, info.duration, info.name.UTF8String, "", "date not need", "time not need", 0, ICH_FILE_TYPE_VIDEO, info.thumnailSize, NO);
    
    SHCameraObject *cameraObj = [self getCameraWithUUID:self.camUid];
    if (cameraObj == nil) {
        return data;
    }
    data = [cameraObj.controler.propCtrl requestThumbnail:&file andPropertyID:TRANS_PROP_GET_FILE_THUMBNAIL andCamera:cameraObj];
    return data;
}

- (NSArray<MsgFileInfo *> *)getFileWithStartDatetime:(NSString *)dateTime andEndDateTime:(NSString *)endDateTime {
    
    //需要将datetime 转换为 date
    NSString *start = [self getDateFromDatetime:dateTime];
    NSString *end = [self getDateFromDatetime:dateTime];
    NSMutableArray *arr = [NSMutableArray new];
    SHCameraObject *cameraObj = [self getCameraWithUUID:self.camUid];
    if (cameraObj == nil) {
        return [arr copy];
    }
    
    BOOL success = NO;
    map<string, int> storageInfoMap = [cameraObj.sdk getFilesStorageInfoWithStartDate:start andEndDate:end success:&success];
    if (!success) {
        return [arr copy];
    }
    int i = 0;
    
    for (map<string, int>::iterator it = storageInfoMap.begin(); it != storageInfoMap.end(); ++it, ++i) {
        SHLogInfo(SHLogTagAPP, @"key: %s - value: %d", (it->first).c_str(), it->second);
        vector<ICatchFile> fileList = [cameraObj.sdk listFilesWhithDate:it->first andStartIndex:0 andNumber:it->second];
        for (vector<ICatchFile>::iterator it = fileList.begin(); it != fileList.end(); ++it) {
            
            MsgFileInfo *info = [MsgFileInfo new];
            info.handle = it->getFileHandle();
            info.name = [NSString stringWithFormat:@"%s", it->getFileName().c_str()];
            info.duration = it->getFileDuration();
            info.thumnailSize = it->getFileThumbSize();
            
            NSString *dateTime = [NSString stringWithFormat:@"%s %s", it->getFileDate().c_str(), it->getFileTime().c_str()];
            info.datetime = [TimeHelper outterFormatToInnerFormat:dateTime];
            
            [arr addObject:info];
        }
    }
    return arr;
}

- (BOOL)loginWithInfo:(NSString *)info
{
    NSLog(@"will connect to %@", info);
    return YES;
}
@end
