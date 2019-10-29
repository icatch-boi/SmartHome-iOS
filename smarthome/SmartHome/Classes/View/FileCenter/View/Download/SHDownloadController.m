// SHDownloadController.m

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
 
 // Created by zj on 2019/10/25 4:32 PM.
    

#import "SHDownloadController.h"
#import "SHDownloadCell.h"
#import "SHFCDownloaderOpManager.h"

@interface SHDownloadController ()<SHFCDownloaderOpManagerDelegate, SHDownloadCellDelegate>

@end

@implementation SHDownloadController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
    [self addObserver];
}

- (void)dealloc {
    [self removeObserver];
}

#pragma mark - GUI
- (void)setupGUI {
    self.tableView.rowHeight = 60;
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadCompletionHandle:) name:kDownloadCompletionNotification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDownloadCompletionNotification object:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self listArray].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHDownloadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadCell" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.fileInfo = [self listArray][indexPath.row];
    cell.optionItem = self.optionItem;
    cell.delegate = self;
    
    return cell;
}

#pragma mark - SHDownloadCellDelegate
- (void)buttonClickedActionWithCell:(SHDownloadCell *)cell {
    SEL selector = NSSelectorFromString(cell.optionItem.methodName);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObject:cell.fileInfo afterDelay:0];
    }
}

- (void)cancelDownload:(SHS3FileInfo *)fileInfo {
    [[SHFCDownloaderOpManager sharedDownloader] cancelDownload:fileInfo];
}

- (void)enterLocalAlbum {
    if (self.enterLocalAlbumBlock) {
        self.enterLocalAlbumBlock();
    }
}

#pragma mark - SHFCDownloaderOpManager
- (void)startDownloadWithFileInfo:(SHS3FileInfo *)fileInfo {
    NSInteger row = [[self listArray] indexOfObject:fileInfo];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    });
}

- (void)downloadCompletionWithFileInfo:(SHS3FileInfo *)fileInfo {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)downloadCompletionHandle:(NSNotification *)nc {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Load Data
- (NSArray *)listArray {
    SHDownloadItem *item = [[SHFCDownloaderOpManager sharedDownloader] downloadItemWithDeviceID:self.deviceID];
    if ([self.optionItem.title isEqualToString:@"正在下载"]) {
        return item.downloadArray.copy;
    } else {
        return item.finishedArray.copy;
    }
}

@end
