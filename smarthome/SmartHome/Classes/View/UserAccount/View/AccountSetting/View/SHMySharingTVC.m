// SHMySharingTVC.m

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
 
 // Created by zj on 2019/7/23 5:35 PM.
    

#import "SHMySharingTVC.h"
#import "SHSubscriberCell.h"
#import "SHSubscriberGroup.h"
#import <SHAccountManagementKit/SHAccountManagementKit.h>
#import "SHGroupHeaderView.h"
#import "SVProgressHUD.h"
#import "SHNetworkManagerHeader.h"
#import "SHSubscriberInfo.h"
#import <MJRefresh/MJRefresh.h>

static NSString * const kSubscriberCellReuseID = @"SubscriberCell";
static NSString * const kGroupHeaderReuseID = @"GroupHeader";
static const CGFloat kDefaultRowHeight = 50.0;

@interface SHMySharingTVC () <SHGroupHeaderViewDelegate, SHSubscriberCellDelegate>

@property (nonatomic, strong) NSArray<SHSubscriberGroup *> *groups;
@property (nonatomic, weak) UIView *noSubscriberView;

@end

@implementation SHMySharingTVC

+ (instancetype)mySharingTVC {
    SHMySharingTVC *vc = [[SHMySharingTVC alloc] initWithStyle:UITableViewStylePlain];
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self setupGUI];
//    [self loadData];
}

- (void)setupGUI {
    [self.tableView registerClass:[SHSubscriberCell class] forCellReuseIdentifier:kSubscriberCellReuseID];
    [self.tableView registerClass:[SHGroupHeaderView class] forHeaderFooterViewReuseIdentifier:kGroupHeaderReuseID];
    self.tableView.rowHeight = kDefaultRowHeight;
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    [self setupRefreshView];
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
    WEAK_SELF(self);
    [SHSubscriberGroup loadSubscriberGroupData:^(NSArray<SHSubscriberGroup *> * _Nonnull subscriberGroups) {
        STRONG_SELF(self);
        [self.tableView.mj_header endRefreshing];

        if (subscriberGroups.count > 0) {
            [self removeNoSubscriberView];

            self.groups = subscriberGroups;
            [self.tableView reloadData];
        } else {
            [self setupNoSubscriberView];
        }
    }];
}

- (void)setupNoSubscriberView {
    if (self.noSubscriberView != nil) {
        return;
    }
    
    UIView *view = [[UIView alloc] initWithFrame:[self calcNoSubscriberViewFrame]];
    
    CGFloat labelH = 44.0;
    CGFloat margin = 0; //12;
    UIImageView *imgView = [UIImageView imageViewWithImage:[UIImage imageNamed:@"subscribe_share"]];
    [view addSubview:imgView];
    imgView.center = CGPointMake(view.center.x, (CGRectGetHeight(view.frame) - labelH - margin) * (1 - 0.618));
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imgView.frame) + margin, CGRectGetWidth(view.frame), labelH)];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = NSLocalizedString(@"kNoDevicesToShare", nil);
    label.textColor = [UIColor ic_colorWithHex:kTextColor];
    [view addSubview:label];
    
    [self.tableView addSubview:view];
    
    self.noSubscriberView = view;
}

- (CGRect)calcNoSubscriberViewFrame {
    CGRect rect = self.view.frame;
    //获取状态栏的rect
    CGRect statusRect = [[UIApplication sharedApplication] statusBarFrame];
    //获取导航栏的rect
    CGRect navRect = self.navigationController.navigationBar.frame;
    return CGRectMake(CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetWidth(rect), CGRectGetHeight(rect) - CGRectGetHeight(statusRect) - CGRectGetHeight(navRect));
}

- (void)removeNoSubscriberView {
    if (self.noSubscriberView == nil) {
        return;
    }
    
    [self.noSubscriberView removeFromSuperview];
    self.noSubscriberView = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SHSubscriberGroup *group = self.groups[section];
    if (group.isVisible) {
        return group.subscribers.count;
    } else {
        return 0;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHSubscriberCell *cell = [tableView dequeueReusableCellWithIdentifier:kSubscriberCellReuseID forIndexPath:indexPath];
    
    // Configure the cell...
    cell.subscriber = self.groups[indexPath.section].subscribers[indexPath.row];
    cell.delegate = self;
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SHGroupHeaderView *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kGroupHeaderReuseID];
    header.tag = section;
    
    SHSubscriberGroup *group = self.groups[section];
    header.group = group;
    header.delegate = self;
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kDefaultRowHeight;
}

- (void)groupHeaderViewDidClickTitleButton:(SHGroupHeaderView *)groupHeaderView {
    // 刷新table view
    //[self.tableView reloadData];
    
    // 局部刷新(只刷新某个组)
    // 创建一个用来表示某个组的对象
    NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:groupHeaderView.tag];
    
    if (self.tableView.style == UITableViewStyleGrouped && groupHeaderView.tag == 0) {
        
        groupHeaderView.group = self.groups[groupHeaderView.tag];
    }
    
    [self.tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
}

- (void)subscriberCellDidClickDeleteButton:(SHSubscriberCell *)cell {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    SHSubscriberGroup *group = self.groups[indexPath.section];

    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];
    
    WEAK_SELF(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] removeCameraSubscriberWithCameraID:group.cameraID userID:group.subscribers[indexPath.row].subscriber.userId completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"removeCameraSubscriberWithCameraID is success: %d", isSuccess);
            
            STRONG_SELF(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                
                if (isSuccess) {
                    NSMutableArray<SHSubscriberGroup *> *temp = [NSMutableArray arrayWithArray:self.groups];
                    NSMutableArray<SHSubscriberInfo *> *subscribers = [NSMutableArray arrayWithArray:group.subscribers];
                    [subscribers removeObjectAtIndex:indexPath.row];
                    SHSubscriberGroup *tempG = [SHSubscriberGroup subscriberGroupWithName:group.name cameraID:group.cameraID subscribers:subscribers];
                    [temp replaceObjectAtIndex:indexPath.section withObject:tempG];
                    
                    self.groups = temp;
                    
                    NSIndexSet *idxSet = [NSIndexSet indexSetWithIndex:indexPath.section];
                    
                    [self.tableView reloadSections:idxSet withRowAnimation:UITableViewRowAnimationFade];
                } else {
                    Error *error = result;
                    SHLogError(SHLogTagAPP, @"removeCameraSubscriberWithCameraID failed: %@", error.error_description);
                    
                    [SVProgressHUD showErrorWithStatus:error.error_description];
                    [SVProgressHUD dismissWithDelay:2.0];
                }
            });
        }];
    });
}

@end
