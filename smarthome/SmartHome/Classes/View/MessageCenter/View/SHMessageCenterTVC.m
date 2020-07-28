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
#import "UIButton+Badge.h"

static NSString * const kMessageCellID = @"MessageCellID";
static void *SHMessageCenterTVCContext = &SHMessageCenterTVCContext;

@interface SHMessageCenterTVC ()

@property (nonatomic, strong) SHMessageListViewModel *listViewModel;
@property (nonatomic, assign, getter=isPullup) BOOL pullup;
@property (nonatomic, strong) SHCameraObject *cameraObj;
@property (nonatomic, weak) UIButton *badgeButton;

@end

@implementation SHMessageCenterTVC

+ (instancetype)messageCenterTVCWithCameraObj:(SHCameraObject *)cameraObj {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kMessageCenterStoryboardName bundle:nil];
    SHMessageCenterTVC *vc = [sb instantiateInitialViewController];
    vc.cameraObj = cameraObj;
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
    [self setupPullupRefreshView];
    
    self.title = NSLocalizedString(@"kMessageCenter", nil);
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(backTopAndRefresh)];
    [self setupNavigationItem];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    WEAK_SELF(self);
    [_cameraObj setUpdateNewMessageCount:^{
        [weakself updateBadgeDisplay];
    }];
}

- (void)setupNavigationItem {
    UIButton *button = [[UIButton alloc] init];
    self.badgeButton = button;

    [button setImage:[UIImage imageNamed:@"nav-btn-refresh"] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(backTopAndRefresh) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    button.shouldHideBadgeAtZero = YES;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    [self updateBadgeDisplay];
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

- (void)setupPullupRefreshView {
    WEAK_SELF(self);
    MJRefreshAutoNormalFooter *footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        weakself.pullup = YES;
        [weakself loadData];
    }];
    
    // 设置文字
    [footer setTitle:@"Click or drag up to refresh" forState:MJRefreshStateIdle];
    [footer setTitle:@"Loading more ..." forState:MJRefreshStateRefreshing];
    [footer setTitle:@"No more data" forState:MJRefreshStateNoMoreData];
    
    // 设置字体
    footer.stateLabel.font = [UIFont systemFontOfSize:15];
    
    // 设置颜色
    footer.stateLabel.textColor = [UIColor ic_colorWithHex:kButtonDefaultColor];
    
    // 设置footer
    self.tableView.mj_footer = footer;
}

- (void)backTopAndRefresh {
    [_cameraObj resetNewMessageCount];
    //!< 说明 section不能为NSNotFound row可以为NSNotFound，避免无数据时，引起崩溃😖
    if (self.tableView.numberOfSections) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:NSNotFound inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    
    [self.tableView.mj_header beginRefreshing];
}

- (void)loadData {
    [self.listViewModel loadMessageWithCamera:self.cameraObj.camera pullup:self.isPullup completion:^(BOOL isSuccess, BOOL shouldRefresh) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.isPullup) {
                [self.tableView.mj_footer endRefreshing];
            } else {
                [self.tableView.mj_header endRefreshing];
            }

            self.pullup = NO;
            
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

- (void)updateBadgeDisplay {
    _badgeButton.badgeValue = [NSString stringWithFormat:@"%lu", (unsigned long)_cameraObj.newMessageCount];
    _badgeButton.badgeBGColor = [UIColor orangeColor];
    _badgeButton.badgeOriginX = CGRectGetWidth(_badgeButton.bounds) - _badgeButton.badge.frame.size.width/2 - _badgeButton.badgePadding * 0.5;
}

@end
