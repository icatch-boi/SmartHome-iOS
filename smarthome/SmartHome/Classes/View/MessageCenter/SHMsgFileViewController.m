// SHMsgFileViewController.m

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
 
 // Created by sa on 2018/3/30 下午5:43.
    

#import "SHMsgFileViewController.h"
#import "SHFileInfoTableViewCell.h"
#import "SHVideoPlaybackVC.h"
#import "MsgFileInfo.h"
#import "ICatchFile.h"
#import "SHFileTable.h"
#import "TimeHelper.h"
@interface SHMsgFileViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *fileInfoTabelView;

@property (nonatomic) dispatch_queue_t fileInfoQueue;
@property (nonatomic,strong) NSArray* fileInfoArr;
@property (nonatomic) MBProgressHUD *progressHUD;
@property dispatch_semaphore_t sourceSem;
@end

@implementation SHMsgFileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileInfoTabelView.delegate = self;
    self.fileInfoTabelView.dataSource = self;
    _sourceSem = dispatch_semaphore_create(1);
    [self.fileInfoTabelView setRowHeight:100];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray*)fileInfoArr
{
    if (dispatch_semaphore_wait(_sourceSem, 10 * NSEC_PER_MSEC) != 0) {
        NSLog(@"get null arr");
        return nil;
    }
    if(_fileInfoArr == nil) {
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kLoading", nil)];
        //[self.progressHUD hideProgressHUD:NO];
        dispatch_async(self.fileInfoQueue, ^{
            _fileInfoArr = [_msgCenter getFileListWithMessageInfo:_msgInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                [self.fileInfoTabelView reloadData];
            });
            
            dispatch_semaphore_signal(_sourceSem);
        });
    } else {
        dispatch_semaphore_signal(_sourceSem);
    }
    
    return _fileInfoArr;
}

- (dispatch_queue_t)fileInfoQueue
{
    if(_fileInfoQueue == nil) {
        _fileInfoQueue = dispatch_queue_create("SmartHoem.GCD.Queue.FileInfo.GetInfo", 0);
    }
    return _fileInfoQueue;
}

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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.fileInfoArr.count;
}

- (SHFileInfoTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"fileListCellID";
    SHFileInfoTableViewCell* cell = [self.fileInfoTabelView dequeueReusableCellWithIdentifier:cellID];
    //取list，取thumbnail 需要异步。
    MsgFileInfo *fileInfo = [_fileInfoArr objectAtIndex:indexPath.row];
    
    cell.thumbnailImage.image = [UIImage imageNamed:@"empty_photo"];
    
    cell.timeLabel.text = [TimeHelper getTimeWithString:fileInfo.datetime];
    cell.durationLabel.text = [NSString stringWithFormat:@"%d", fileInfo.duration];
    dispatch_async(self.fileInfoQueue, ^{
        NSData *data = [_msgCenter getThumbnailWithMsgFileInfo:fileInfo];
        
        if(data != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SHFileInfoTableViewCell *c = (SHFileInfoTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                
                if (c) {
                    c.thumbnailImage.image = [UIImage imageWithData:data];
                }
            });
        }
    });
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIStoryboard *mainBoard = [UIStoryboard storyboardWithName:kAlbumStoryboardName bundle:nil];
    SHVideoPlaybackVC *videoPlayVC = [mainBoard instantiateViewControllerWithIdentifier:@"videoPlaybackView"];

    MsgFileInfo * info = [_fileInfoArr objectAtIndex:indexPath.row];
    NSData *img = [_msgCenter getThumbnailWithMsgFileInfo:info];
    videoPlayVC.previewImage = [UIImage imageWithData:img];
    videoPlayVC.index = 0;
    videoPlayVC.cameraUid = _uuid;
    
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
    
    [self.navigationController pushViewController:videoPlayVC animated:YES];
}
@end
