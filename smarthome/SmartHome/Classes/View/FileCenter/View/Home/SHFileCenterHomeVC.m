//
//  SHFileCenterHomeVC.m
//  FileCenter
//
//  Created by ZJ on 2019/10/15.
//  Copyright © 2019 iCatch Technology Inc. All rights reserved.
//

#import "SHFileCenterHomeVC.h"
#import "SHDateView.h"
#import "SHFileCenterHomeCell.h"
#import "SHENetworkManagerCommon.h"
#import "SHFileCenterCommon.h"
#import "SHFileInfoViewModel.h"
#import "SVProgressHUD.h"
#import "SHAVPlayerViewController.h"

@interface SHFileCenterHomeVC () <UICollectionViewDataSource, UICollectionViewDelegate, SHDateViewDelete, SHFileCenterHomeCellDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) NSArray *dateFileInfos;

@property (nonatomic, assign) int currentIndex;

@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, strong) SHFileInfoViewModel *fileInfoViewModel;

@end

@implementation SHFileCenterHomeVC

+ (UINavigationController *)fileCenterHomeVCWithDeviceID:(NSString *)deviceID {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"FileCenter" bundle:nil];
    UINavigationController *nav = [sb instantiateInitialViewController];
    
    SHFileCenterHomeVC *vc = (SHFileCenterHomeVC *)nav.topViewController;
    vc.deviceID = deviceID;
    
    return nav;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    NSDate *date = [@"2019/10/01" convertToDateWithFormat:@"yyyy/MM/dd"];
    [self loadDateFileInfoWithDate:[NSDate date]];
}

#pragma mark - GUI
- (void)setupGUI {
    self.flowLayout.itemSize = self.collectionView.bounds.size;
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.minimumLineSpacing = 0;
    self.flowLayout.minimumInteritemSpacing = 0;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.bounces = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
    
    [self loadDateView];
}

// 在导航控制器中如果出现了 scrollview，会自动加上64的偏移
- (void)loadDateView {
    // 不让控制器自动生成64的偏移
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.scrollView.contentInsetAdjustmentBehavior = NO;
    
    CGFloat marginX = 0;
    CGFloat x = marginX;
    CGFloat h = CGRectGetHeight(self.scrollView.frame);
    CGFloat w = (CGRectGetWidth(self.scrollView.frame) - marginX * kFileCenterShowDays) / kFileCenterShowDays;
    
    for (int i = 0; i < kFileCenterShowDays; i++) {
        SHDateView *dateView = [SHDateView dateViewWithTitle:nil];
        dateView.delegate = self;
        
        [self.scrollView addSubview:dateView];
        
        dateView.frame = CGRectMake(x, 0, MAX(w, kDateViewMinWidth /*dateView.bounds.size.width*/), h);
        x += dateView.bounds.size.width + marginX;
    }
    
    // 设置滚动范围
    self.scrollView.contentSize = CGSizeMake(x, 0);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
//    SHDateView *view = self.scrollView.subviews[0];
//    view.scale = 1.0;
}

// 当计算好collectionView的大小，再设置cell的大小
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (void)updateTitle:(NSDate *)date {
    dispatch_async(dispatch_get_main_queue(), ^{
        _titleLabel.text = [self createTitleWithDate:date];
    });
}

#pragma mark - Load Data
- (void)loadDateFileInfoWithDate:(NSDate *)date {
    [SVProgressHUD showWithStatus:nil];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    WEAK_SELF(self);
    [self.fileInfoViewModel loadDateFileInfoWithDate:date completion:^(NSArray<SHDateFileInfo *> * _Nonnull dateFileInfos) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            
            weakself.dateFileInfos = dateFileInfos;
            [weakself updateTitle:date];
        });
    }];
}

- (void)setDateFileInfos:(NSArray *)dateFileInfos {
    _dateFileInfos = dateFileInfos;
    
    [self.collectionView reloadData];
    [self updateDateFileInfoData];
}

- (void)updateDateFileInfoData {
    __block SHDateView *lastView = self.scrollView.subviews[kFileCenterShowDays - 1];;
    
    [self.dateFileInfos enumerateObjectsUsingBlock:^(SHDateFileInfo*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIView *view = self.scrollView.subviews[idx];
        if ([view isKindOfClass:[SHDateView class]]) {
            SHDateView *dateView = (SHDateView *)view;
            dateView.dateFileInfo = obj;
            
            if (obj.exist) {
                lastView = dateView;
            }
        }
    }];
    
    lastView.scale = 1;
    [self clickedActionWithDateView:lastView];
}

- (NSString *)createTitleWithDate:(NSDate *)curDate {
    NSString *curMonth = [curDate convertToStringWithFormat:@"MM"];
    NSString *titleString = [NSString stringWithFormat:@"%@", [[SHCamStaticData instance] monthStringDict][curMonth]];
    
    BOOL done = NO;
    for (int i = 0; i < kFileCenterShowDays; i++) {
        //单位为秒
        NSDate *date = [NSDate dateWithTimeInterval:-24 * 60 * 60 * i sinceDate:curDate];
        
        NSString *month = [date convertToStringWithFormat:@"MM"];
        if (![month isEqualToString:curMonth]) {
            if (!done) {
                //夸月处理
                titleString = [NSString stringWithFormat:@"%@/%@", [[SHCamStaticData instance] monthStringDict][month], [[SHCamStaticData instance] monthStringDict][curMonth]];
                done = YES;
            }
        }
    }
    
    return titleString;
}

#pragma mark - Action
- (IBAction)returnBackAction:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)calendarClickAction:(id)sender {
    
}

#pragma mark - UICollectonViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dateFileInfos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SHFileCenterHomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"files" forIndexPath:indexPath];
    
    cell.dateFileInfo = self.dateFileInfos[indexPath.row];
    cell.delegate = self;
    
    return cell;
}

// collectionView的代理方法
// collectionView 正在滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 当前dateView
    SHDateView *dateView = self.scrollView.subviews[self.currentIndex];
    
//    int index = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    // 下一个dateView
    SHDateView *nextDateView = nil;
    // 遍历当前可见 cell 的索引
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        if (indexPath.item != self.currentIndex) {
            nextDateView = self.scrollView.subviews[indexPath.item];
            break;
        }
    }
    
    if (nextDateView == nil) {
        return;
    }
    
    // 获取滚动的比例
    CGFloat nextScale = ABS(scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds) - self.currentIndex);
    CGFloat currentScale = 1 - nextScale;

    dateView.scale = currentScale;
    nextDateView.scale = nextScale;
}

// 滚动结束之后，计算currentIndex
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    self.currentIndex = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);

    // 居中显示当前显示的标签
    SHDateView *dateView = self.scrollView.subviews[self.currentIndex];
    CGFloat offset = dateView.center.x - CGRectGetWidth(scrollView.bounds) * 0.5;
    CGFloat maxOffset = self.scrollView.contentSize.width - dateView.bounds.size.width - CGRectGetWidth(scrollView.bounds);
    if (offset < 0) {
        offset = 0;
    } else if (offset > maxOffset) {
        offset = maxOffset + dateView.bounds.size.width;
    }

    [self.scrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.currentIndex = (scrollView.contentOffset.x + CGRectGetWidth(scrollView.bounds) * 0.5) / CGRectGetWidth(scrollView.bounds);
}

#pragma mark - SHDateViewDelete
- (void)clickedActionWithDateView:(SHDateView *)dateView {
    NSLog(@"clickedActionWithDateView");
    
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (dateView == obj) {
            self.currentIndex = (int)idx;
            *stop = YES;
        }
    }];

    // 居中显示当前显示的标签
    CGFloat offset = dateView.center.x - CGRectGetWidth(self.collectionView.bounds) * 0.5;
    CGFloat maxOffset = self.scrollView.contentSize.width - dateView.bounds.size.width - CGRectGetWidth(self.collectionView.bounds);
    if (offset < 0) {
        offset = 0;
    } else if (offset > maxOffset) {
        offset = maxOffset + dateView.bounds.size.width;
    }
    
    [self.scrollView setContentOffset:CGPointMake(offset, 0) animated:YES];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

#pragma mark - SHFileCenterHomeCellDelegate
- (void)fileCenterHomeCell:(SHFileCenterHomeCell *)cell didSelectWithFileInfo:(SHS3FileInfo *)fileInfo {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SHAVPlayerViewController *vc = [[SHAVPlayerViewController alloc] initWithFileInfo:fileInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.navigationBarHidden = YES;
            
            [self.navigationController presentViewController:nav animated:YES completion:nil];
        });
    });
}

#pragma mark - Init
- (SHFileInfoViewModel *)fileInfoViewModel {
    if (_fileInfoViewModel == nil) {
        _fileInfoViewModel = [SHFileInfoViewModel fileInfoViewModelWithDeviceID:_deviceID];
    }
    
    return _fileInfoViewModel;
}

@end
