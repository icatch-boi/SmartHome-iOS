// SHMessageCenterTVC.m

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
 
 // Created by zj on 2019/7/26 3:29 PM.
    

#import "SHMessageCenterTVC.h"
#import "SHMessageCell.h"
#import <MJRefresh/MJRefresh.h>
#import "SHMessageListViewModel.h"
#import "SHSingleImageDisplayVC.h"

static NSString * const kMessageCellID = @"MessageCellID";

@interface SHMessageCenterTVC ()

@property (nonatomic, strong) SHMessageListViewModel *listViewModel;
@property (nonatomic, assign, getter=isPullup) BOOL pullup;
@property (nonatomic, strong) SHCamera *camera;

@end

@implementation SHMessageCenterTVC

+ (instancetype)messageCenterTVCWithCamera:(SHCamera *)camera {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    SHMessageCenterTVC *vc = [sb instantiateInitialViewController];
    vc.camera = camera;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
}

- (void)setupGUI {
    self.tableView.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
    self.tableView.rowHeight = 100;
    
    [self setupRefreshView];
    
    self.title = @"消息中心";
}

- (void)setupRefreshView {
    WEAK_SELF(self);
    MJRefreshNormalHeader *header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        [weakself loadData];
    }];
    
    // 设置文字
    [header setTitle:@"Pull down to refresh" forState:MJRefreshStateIdle];
    [header setTitle:@"Release to refresh" forState:MJRefreshStatePulling];
    [header setTitle:@"Loading ..." forState:MJRefreshStateRefreshing];
    
    // 设置字体
    header.stateLabel.font = [UIFont systemFontOfSize:15];
    header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];
    
    // 设置颜色
    header.stateLabel.textColor = [UIColor ic_colorWithHex:kButtonDefaultColor];
    header.lastUpdatedTimeLabel.textColor = [UIColor ic_colorWithHex:kButtonThemeColor];
    
    header.automaticallyChangeAlpha = YES;
    
    // 马上进入刷新状态
    [header beginRefreshing];
    
    // 设置刷新控件
    self.tableView.mj_header = header;
}

- (void)loadData {
    [self.listViewModel loadMessageWithCamera:self.camera pullup:self.isPullup completion:^(BOOL isSuccess, BOOL shouldRefresh) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView.mj_header endRefreshing];

            if (shouldRefresh) {
                [self.tableView reloadData];
            }
        });
    }];
}

- (SHMessageListViewModel *)listViewModel {
    if (_listViewModel == nil) {
        _listViewModel = [SHMessageListViewModel new];
    }
    
    return _listViewModel;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.listViewModel.messageList.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:kMessageCellID forIndexPath:indexPath];
    
    // Configure the cell...
    cell.messageInfo = self.listViewModel.messageList[indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHMessageInfo *messageInfo = self.listViewModel.messageList[indexPath.row];
    SHSingleImageDisplayVC *vc = [SHSingleImageDisplayVC singleImageDisplayVCWithMessageInfo:messageInfo];
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
