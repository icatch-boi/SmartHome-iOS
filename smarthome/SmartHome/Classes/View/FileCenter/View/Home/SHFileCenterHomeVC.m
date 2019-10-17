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

@interface SHFileCenterHomeVC () <UICollectionViewDataSource, UICollectionViewDelegate, SHDateViewDelete>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) NSArray *dates;

@property (nonatomic, assign) int currentIndex;

@end

@implementation SHFileCenterHomeVC

+ (instancetype)fileCenterHomeVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"FileCenter" bundle:nil];
    
    return [sb instantiateInitialViewController];
}

- (NSArray *)dates {
    if (_dates == nil) {
        _dates = @[@"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18"
                  ];
    }
    
    return _dates;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupGUI];
    [self loadDays];
}

- (void)setupGUI {
    self.flowLayout.itemSize = self.collectionView.bounds.size;
    self.flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    self.flowLayout.minimumLineSpacing = 0;
    self.flowLayout.minimumInteritemSpacing = 0;
    
    self.collectionView.pagingEnabled = YES;
    self.collectionView.bounces = NO;
    self.collectionView.showsHorizontalScrollIndicator = NO;
}

// 在导航控制器中如果出现了 scrollview，会自动加上64的偏移
- (void)loadDays {
    // 不让控制器自动生成64的偏移
//    self.automaticallyAdjustsScrollViewInsets = NO;
//    self.scrollView.contentInsetAdjustmentBehavior = NO;
    
    CGFloat marginX = 0;
    CGFloat x = marginX;
    CGFloat h = CGRectGetHeight(self.scrollView.frame);
    CGFloat w = (CGRectGetWidth(self.scrollView.frame) - marginX * self.dates.count) / self.dates.count;
    
    for (NSString *temp in self.dates) {
        SHDateView *dateView = [SHDateView dateViewWithTitle:temp];
        dateView.delegate = self;
        
        [self.scrollView addSubview:dateView];
        
        dateView.frame = CGRectMake(x, 0, MAX(w, dateView.bounds.size.width), h);
        x += dateView.bounds.size.width + marginX;
    }
    
    // 设置滚动范围
    self.scrollView.contentSize = CGSizeMake(x, 0);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    
    SHDateView *view = self.scrollView.subviews[0];
    view.scale = 1.0;
}

// 当计算好collectionView的大小，再设置cell的大小
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.flowLayout.itemSize = self.collectionView.bounds.size;
}

- (IBAction)returnBackAction:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectonViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dates.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SHFileCenterHomeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"files" forIndexPath:indexPath];
    
    cell.dateString = self.dates[indexPath.row];
    
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

@end
