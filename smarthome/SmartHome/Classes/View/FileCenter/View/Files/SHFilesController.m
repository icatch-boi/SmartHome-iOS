//
//  SHFilesController.m
//  FileCenter
//
//  Created by ZJ on 2019/10/16.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFilesController.h"
#import "SHFilesCell.h"
#import "SHFilesViewModel.h"
#import "SVProgressHUD.h"
#import "SHOperationView.h"
#import "SHFileCenterCommon.h"
#import <MJRefresh/MJRefresh.h>

static void * SHFilesControllerContext = &SHFilesControllerContext;

@interface SHFilesController ()<SHFilesCellDelegate, SHOperationViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) SHOperationView *selectNumOpView;
@property (weak, nonatomic) SHOperationView *selectOpView;

@property (nonatomic, strong) NSArray<SHS3FileInfo *> *filesList;
@property (nonatomic, strong) SHFilesViewModel *filesViewModel;
@property (nonatomic, assign) BOOL editState;
@property (nonatomic, assign, getter=isPullup) BOOL pullup;
@property (nonatomic, strong) MJRefreshNormalHeader *header;
@property (nonatomic, strong) MJRefreshAutoNormalFooter *footer;

@end

@implementation SHFilesController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
//    self.view.backgroundColor = [UIColor colorWithRed:arc4random_uniform(256) / 255.0 green:arc4random_uniform(256) / 255.0 blue:arc4random_uniform(256) / 255.0 alpha:1.0];
    [self setupGUI];
    [self addObserver];
}

- (void)dealloc {
    [self removeObserver];
}

- (void)addObserver {
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(editState)) options:NSKeyValueObservingOptionNew context:SHFilesControllerContext];
    [self.filesViewModel addObserver:self forKeyPath:NSStringFromSelector(@selector(selectedFiles)) options:NSKeyValueObservingOptionNew context:SHFilesControllerContext];
}

- (void)removeObserver {
    [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(editState)) context:SHFilesControllerContext];
    [self.filesViewModel removeObserver:self forKeyPath:NSStringFromSelector(@selector(selectedFiles)) context:SHFilesControllerContext];
}

#pragma mark - GUI
- (void)setupGUI {
    self.tableView.rowHeight = [SHFilesViewModel filesCellRowHeight];
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self setupFooterView];
    [self updateSelectNumber];
    
    [self setupRefreshView];
    [self setupPullupRefreshView];
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
//    [header beginRefreshing];
    
    // 设置刷新控件
    self.tableView.mj_header = header;
    self.header = header;
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
    self.footer = footer;
}

- (void)setupFooterView {
    NSInteger operationNum = self.filesViewModel.operationItems.count;
    
    CGFloat marginX = 0;
    CGFloat x = marginX;
    CGFloat h = CGRectGetHeight(self.footerView.frame);
    CGFloat w = (CGRectGetWidth(self.footerView.frame) - marginX * operationNum) / operationNum;
    
    for (int i = 0; i < operationNum; i++) {
        SHOperationView *view = [SHOperationView operationView];
        view.item = self.filesViewModel.operationItems[i];
        view.delegate = self;
        
        [self.footerView addSubview:view];
        
        view.frame = CGRectMake(x, 0, w, h);
        x += view.bounds.size.width + marginX;
        
        if ([view.subTitle isEqualToString:@"全选"]) {
            self.selectOpView = view;
        } else if ([view.subTitle isEqualToString:@"已选择"]) {
            self.selectNumOpView = view;
        }
    }
    
    self.footerView.alpha = 0;
}

- (void)updateFooterView {
    self.footerView.alpha = self.editState ? 0.85 : 0;
    
    [self.tableView reloadData];
}

- (void)updateSelectNumber {
    self.selectNumOpView.title = @(self.filesViewModel.selectedFiles.count).stringValue;
    
    [self updateSelectOpView];
    [self updateOtherOpView];
}

- (void)updateSelectOpView {
    if (self.filesList.count != self.filesViewModel.selectedFiles.count) {
        self.selectOpView.icon = [UIImage imageNamed:@"ic_unselected_white_24dp"];
        self.selectOpView.subTitle = @"全选";
        self.selectOpView.tag = 0;
    } else {
        self.selectOpView.icon = [UIImage imageNamed:@"ic_select_all_white_24dp"];
        self.selectOpView.subTitle = @"取消全选";
        self.selectOpView.tag = 1;
    }
}

- (void)updateOtherOpView {
    for (SHOperationView *view in self.footerView.subviews) {
        if ([view isKindOfClass:[SHOperationView class]] &&
            view != self.selectOpView &&
            view != self.selectNumOpView) {
            view.userInteractionEnabled = self.filesViewModel.selectedFiles.count;
            view.backgroundColor = self.filesViewModel.selectedFiles.count ? [UIColor clearColor] : [UIColor ic_colorWithHex:kBackgroundThemeColor alpha:0.5];
        }
    }
}

#pragma mark - Load Data
- (void)loadData {
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    WEAK_SELF(self);
    [self.filesViewModel listFilesWithDeviceID:_dateFileInfo.deviceID date:_dateFileInfo.date pullup:self.isPullup completion:^(NSArray<SHS3FileInfo *> * _Nullable filesInfo) {
        [SVProgressHUD dismiss];
        
        weakself.filesList = filesInfo;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakself.isPullup) {
                [weakself.tableView.mj_footer endRefreshing];
            } else {
                [weakself.tableView.mj_header endRefreshing];
            }
            
            weakself.pullup = NO;
        });
    }];
}

- (void)setDateFileInfo:(SHDateFileInfo *)dateFileInfo {
    _dateFileInfo = dateFileInfo;
    
    self.filesList = nil;
    
    [self.filesViewModel clearInnerCacheData];
    
    if (dateFileInfo.exist) {
        self.tableView.mj_header = self.header;
        self.tableView.mj_footer = self.footer;
        
        [self loadData];
    } else {
        self.tableView.mj_header = nil;
        self.tableView.mj_footer = nil;
    }
}

- (void)setFilesList:(NSArray<SHS3FileInfo *> *)filesList {
    _filesList = filesList;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SHFilesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"files" forIndexPath:indexPath];
    
    // Configure the cell...
    cell.dateFileInfo = self.dateFileInfo;
    cell.fileInfo = self.filesList[indexPath.row];
    cell.delegate = self;
    cell.editState = self.editState;
    
    return cell;
}

#pragma mark - Table view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SHS3FileInfo *fileInfo = self.filesList[indexPath.row];

    if (self.editState) {
        fileInfo.selected = !fileInfo.selected;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [self.filesViewModel addSelectedFile:fileInfo];
    } else {
        if (self.didSelectBlock) {
            self.didSelectBlock(fileInfo);
        }
    }
}

#pragma mark - SHFilesCellDelegate
- (void)longPressGestureHandleWithCell:(SHFilesCell *)cell {
    SHLogTRACE();

    if (self.editState == NO) {
        if (self.editStateBlock) {
            self.editStateBlock();
        }
    }
    
    self.editState = YES;
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}

- (void)cancelEditAction {
    self.editState = NO;

    [self clearSelection];
}

- (void)clearSelection {
    [self clearAllSelect];
    [self.filesViewModel clearSelectedFiles];
}

- (void)selectAllFiles {
    [self.filesList enumerateObjectsUsingBlock:^(SHS3FileInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selected = YES;
    }];
}

- (void)clearAllSelect {
    [self.filesList enumerateObjectsUsingBlock:^(SHS3FileInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.selected = NO;
    }];
}

#pragma mark - SHOperationViewDelegate
- (void)clickedActionWithOperationView:(SHOperationView *)operationView {
    SHOperationItem *item = operationView.item;
    
    SEL selector = NSSelectorFromString(item.methodName);
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObject:operationView afterDelay:0];
    }
}

#pragma mark - Edit Action
- (void)downloadAction {
    SHLogTRACE();
    
    [self.filesViewModel downloadHandleWithDeviceID:self.dateFileInfo.deviceID];
    
    [self clearSelection];
    [self.tableView reloadData];
    
    if (self.enterDownloadBlock) {
        self.enterDownloadBlock();
    }
}

- (void)deleteAction {
    SHLogTRACE();
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", nil) message:@"确定要删除所选文件吗？删除后数据将不能恢复！" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self deleteHandle];
    }]];

    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)selectAllAction:(SHOperationView *)sender {
    if (sender.tag == 0) {
        [self selectAllFiles];
        
        [self.filesViewModel clearSelectedFiles];
        [self.filesViewModel addSelectedFiles:self.filesList];
    } else {
        [self clearSelection];
    }
    
    [self.tableView reloadData];
}

- (void)deleteHandle {
    [SVProgressHUD showWithStatus:@"正在删除..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    WEAK_SELF(self);
    [self.filesViewModel deleteSelectFileWithCompletion:^(NSArray<SHS3FileInfo *> * _Nonnull deleteSuccess, NSArray<SHS3FileInfo *> * _Nonnull deleteFailed) {
        
        NSString *noticeMessage = nil;
        
        if (deleteFailed.count == 0) {
            noticeMessage = NSLocalizedString(@"DeleteDoneMessage", nil);
        } else {
            noticeMessage = NSLocalizedString(@"DeleteMultiError", nil);
            NSString *failedCountString = [NSString stringWithFormat:@"%lu", (unsigned long)deleteFailed.count];
            noticeMessage = [noticeMessage stringByReplacingOccurrencesOfString:@"%d" withString:failedCountString];
        }
        
        [SVProgressHUD showErrorWithStatus:noticeMessage];
        [SVProgressHUD dismissWithDelay:kPromptinfoDisplayDuration];
        
        [weakself deleteResultHandle:deleteSuccess];
    }];
}

- (void)deleteResultHandle:(NSArray<SHS3FileInfo *> *)deletedFiles {
    if (deletedFiles.count == 0) {
        return;
    }
    
    NSMutableArray *temp = [NSMutableArray arrayWithArray:self.filesList];
    [temp removeObjectsInArray:deletedFiles];
    [self.filesViewModel removeSelectedFilesInArray:deletedFiles];
    
    self.filesList = temp.copy;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kPromptinfoDisplayDuration * 0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.filesList.count == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kReloadDateFileInfoNotification object:nil];
        }
    });
}

#pragma mark - Init
- (SHFilesViewModel *)filesViewModel {
    if (_filesViewModel == nil) {
        _filesViewModel = [[SHFilesViewModel alloc] init];
    }
    
    return _filesViewModel;
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == SHFilesControllerContext) {
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(editState))]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateFooterView];
            });
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(selectedFiles))]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSelectNumber];
            });
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
