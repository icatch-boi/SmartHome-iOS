//
//  ZJGridViewController.m
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "ZJGridViewController.h"
#import "ZJGridCell.h"

@interface ZJGridViewController () <UICollectionViewDelegateFlowLayout>

@property (nonatomic, assign) CGFloat marginP;
@property (nonatomic, assign) CGFloat marginL;
@property (nonatomic, assign) CGFloat gutterP;
@property (nonatomic, assign) CGFloat gutterL;
@property (nonatomic, assign) CGFloat columP;
@property (nonatomic, assign) CGFloat columL;

@end

@implementation ZJGridViewController

static NSString * const reuseIdentifier = @"GridCell";

- (instancetype)init
{
    self = [super initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
    if (self) {
        _columP = 3;
        _columL = 4;
        _marginP = 0;
        _marginL = 0;
        _gutterP = 1;
        _gutterL = 1;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            _columP = 6;
            _columL = 8;
            _marginP = 1;
            _marginL = 1;
            _gutterP = 2;
            _gutterL = 2;
        } else if ([UIScreen mainScreen].bounds.size.height == 480) {
            _columP = 3;
            _columL = 4;
            _marginP = 0;
            _marginL = 1;
            _gutterP = 1;
            _gutterL = 2;
        } else {
            _columP = 3;
            _columL = 5;
            _marginP = 0;
            _marginL = 0;
            _gutterP = 1;
            _gutterL = 2;
        }
        
        _initialContentOffset = CGPointMake(0, CGFLOAT_MAX);
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [self init];
    if (self) {
        self.view.frame = frame;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    [self.collectionView registerClass:[ZJGridCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    
    [self setupGUI];
}

- (void)setupGUI {
    self.collectionView.alwaysBounceVertical = YES;
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    [self performLayout];
}

//- (void)adjustOffsetsAsRequired {
//
//    // Move to previous content offset
//    // modify 2018.1.3
//    if ([[UIDevice currentDevice].systemVersion compare:@"11.0"] == NSOrderedAscending) {
//        if (_initialContentOffset.y != CGFLOAT_MAX) {
//            self.collectionView.contentOffset = _initialContentOffset;
//            [self.collectionView layoutIfNeeded]; // Layout after content offset change
//        }
//    }
//
//    // Check if current item is visible and if not, make it so!
//    if (_browser.numberOfPhotos > 0) {
//        NSIndexPath *currentPhotoIndexPath = [NSIndexPath indexPathForItem:_browser.currentIndex inSection:0];
//        NSArray *visibleIndexPaths = [self.collectionView indexPathsForVisibleItems];
//        BOOL currentVisible = NO;
//        for (NSIndexPath *indexPath in visibleIndexPaths) {
//            if ([indexPath isEqual:currentPhotoIndexPath]) {
//                currentVisible = YES;
//                break;
//            }
//        }
//        if (!currentVisible) {
//            [self.collectionView scrollToItemAtIndexPath:currentPhotoIndexPath atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
//        }
//    }
//
//}

- (void)performLayout {
    // modify 2018.1.3
    if ([[UIDevice currentDevice].systemVersion compare:@"11.0" options:NSNumericSearch] == NSOrderedAscending) {
        UINavigationBar *navBar = self.navigationController.navigationBar;
        self.collectionView.contentInset = UIEdgeInsetsMake(navBar.frame.origin.y + navBar.frame.size.height + [self getGutter], 0, 0, 0);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self.collectionView reloadData];
    
    [self performLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// MARK: - Layout
- (CGFloat)getColumn {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return _columP;
    } else {
        return _columL;
    }
}

- (CGFloat)getMargin {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return _marginP;
    } else {
        return _marginL;
    }
}

- (CGFloat)getGutter {
    if (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return _gutterP;
    } else {
        return _gutterL;
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

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_browser numberOfPhotos];
//    return 10;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ZJGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (!cell) {
        cell = [[ZJGridCell alloc] init];
    }
    
    // Configure the cell
    id <ZJPhotoProtocol> photo = [_browser thumbPhotoAtIndex:indexPath.item];
    cell.photo = photo;
//    cell.selectionMode =
    UIImage *img = [_browser imageForPhoto:photo];
    if (img) {
        [cell displayImage];
    } else {
        [photo loadUnderlyingImageAndNotify];
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [_browser setCurrentPhotoIndex:indexPath.row];
    [_browser hideGrid:YES];
}

#pragma mark <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat margin = [self getMargin];
    CGFloat gutter = [self getGutter];
    CGFloat columns = [self getColumn];
    
    CGFloat width = floorf(((self.view.bounds.size.width - (columns - 1) * gutter - 2 * margin) / columns));
    return CGSizeMake(width, width);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return [self getGutter];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return [self getGutter];
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    CGFloat margin = [self getMargin];
    return UIEdgeInsetsMake(margin, margin, margin, margin);
}

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

@end
