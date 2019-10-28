// SHDownloadHomeVC.m

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
 
 // Created by zj on 2019/10/25 11:02 AM.
    

#import "SHDownloadHomeVC.h"
#import "SHOptionView.h"
#import "SHOptionItem.h"
#import "SHDownloadHomeCell.h"

@interface SHDownloadHomeVC ()<SHOptionViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *optionsView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) NSArray<SHOptionItem *> *optionsArray;
@property (nonatomic, assign) int currentIndex;

@end

@implementation SHDownloadHomeVC

+ (instancetype)downloadHomeVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Download" bundle:nil];
    return [sb instantiateInitialViewController];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    
    [self setupOptionViewData];
}

#pragma mark - GUI
- (void)setupGUI {
    [self setupCollectionView];
//    [self setupNavigationItem];
}

- (void)setupCollectionView {
    self.flowLayout.itemSize = self.collectionView.bounds.size;
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.minimumLineSpacing = 0;
    self.flowLayout.minimumInteritemSpacing = 0;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.bounces = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

- (void)setupNavigationItem {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-back"] style:UIBarButtonItemStyleDone target:self action:@selector(returnBackAction)];
}

// 当计算好collectionView的大小，再设置cell的大小
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (void)returnBackAction {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Set Data
- (void)setupOptionViewData {
    WEAK_SELF(self);
    [self.optionsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[SHOptionView class]]) {
            SHOptionView *view = obj;
            view.optionItem = weakself.optionsArray[idx];
            view.delegate = self;
            
            view.scale = !idx;
        }
    }];
}

#pragma mark - UICollectonViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.optionsArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SHDownloadHomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DownloadHomeCell" forIndexPath:indexPath];
    
    cell.optionItem = self.optionsArray[indexPath.row];
    cell.deviceID = self.deviceID;
    
    return cell;
}

#pragma mark - UICollectonViewDelegate
// collectionView的代理方法
// collectionView 正在滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 当前dateView
    SHOptionView *dateView = self.optionsView.subviews[self.currentIndex];
    
//    int index = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    // 下一个dateView
    SHOptionView *nextDateView = nil;
    // 遍历当前可见 cell 的索引
    for (NSIndexPath *indexPath in self.collectionView.indexPathsForVisibleItems) {
        if (indexPath.item != self.currentIndex) {
            nextDateView = self.optionsView.subviews[indexPath.item];
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
}

#pragma mark - SHOptionViewDelegate
- (void)clickedActionWithOptionView:(SHOptionView *)optionView {
    if (_currentIndex == [self.optionsView.subviews indexOfObject:optionView]) {
        return;
    }
    
    [self.optionsView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (optionView == obj) {
            self.currentIndex = (int)idx;
            *stop = YES;
        }
    }];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.currentIndex inSection:0];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

#pragma mark - Init
- (NSArray<SHOptionItem *> *)optionsArray {
    if (_optionsArray == nil) {
        NSArray *options = @[@{@"title": @"正在下载"},
                             @{@"title": @"已完成"}
                             ];
        
        NSMutableArray *temp = [NSMutableArray arrayWithCapacity:options.count];
        [options enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            SHOptionItem *item = [SHOptionItem optionItemWithDict:obj];
            if (item) {
                [temp addObject:item];
            }
        }];
        
        _optionsArray = temp.copy;
    }
    
    return _optionsArray;
}

@end
