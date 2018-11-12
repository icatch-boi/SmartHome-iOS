// ZJPhotoBrowserController.m

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
 
 // Created by zj on 2018/5/29 下午1:48.
    

#import "ZJPhotoBrowserController.h"
#import "ZJGridViewController.h"
#import "ZJPhotoViewerController.h"
#import "SVProgressHUD.h"
#import "UIBarButtonItem+Extensions.h"
#import "SDImageCache.h"

@interface ZJPhotoBrowserController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *fixedPhotosArray;
@property (nonatomic, assign) NSUInteger photoCount;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbPhotos;

@property (nonatomic, strong) ZJGridViewController *gridController;
@property (nonatomic, strong) UIButton *pageCountButton;
@property (nonatomic, assign) NSUInteger currentPageIndex;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) UIPageViewController *pageController;
@property (nonatomic, strong) UIBarButtonItem *returnButtonItem;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *deleteButton;
@property (nonatomic, strong) UIAlertController *actionsSheet;
@property (nonatomic, strong) UIPopoverController *popController;
@property (nonatomic, strong) UIActivityViewController *activityViewController;

@end

@implementation ZJPhotoBrowserController

// MARK: - Init
- (instancetype)init
{
    self = [super init];
    if (self) {
        [self initialisation];
    }
    return self;
}

- (instancetype)initWithDelegate:(id <ZJPhotoBrowserControllerDelegate>)delegate
{
    self = [self init];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithPhotos:(NSArray *)photoArray
{
    self = [self init];
    if (self) {
        _fixedPhotosArray = photoArray;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialisation];
    }
    return self;
}

- (void)initialisation {
    _photoCount = NSNotFound;
    _currentPageIndex = 0;
    _photos = [NSMutableArray array];
    _thumbPhotos = [NSMutableArray array];
    _enableGrid = YES;
    _startOnGrid = NO;
}

- (void)dealloc {
    [self releaseAllUnderlyingPhotos:NO];
    [[SDImageCache sharedImageCache] clearMemory]; // clear memory
}

- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent {
    // Create a copy in case this array is modified while we are looping through
    // Release photos
    NSArray *copy = [_photos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            if (preserveCurrent && p == [self photoAtIndex:self.currentPageIndex]) {
                continue; // skip current
            }
            [p unloadUnderlyingImage];
        }
    }
    // Release thumbs
    copy = [_thumbPhotos copy];
    for (id p in copy) {
        if (p != [NSNull null]) {
            [p unloadUnderlyingImage];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self reloadData];
    [self setupGUI];
}

- (void)setupGUI {
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(close)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(hideGrid)];
    if (_startOnGrid) {
        _enableGrid = YES;
    }
    if (!_enableGrid) {
        _startOnGrid = NO;
    }
    
    [self prepareUI];
    
    _returnButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"  " target:self action:@selector(returnBack) isBack:YES]; //[[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:self action:@selector(returnBack)];
    self.navigationItem.leftBarButtonItem = _returnButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (_startOnGrid) {
        [self showGrid:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)performLayout {
    [self updateNavigation];
    ZJPhotoViewerController *viewer = [self createViewerWithIndex:_currentPageIndex];
    [_pageController setViewControllers:@[viewer]
                              direction:UIPageViewControllerNavigationDirectionForward
                               animated:NO
                             completion:nil];
    _currentViewer = viewer;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)returnBack {
    if (_returnButtonItem) {
        if (self.enableGrid) {
            if (_startOnGrid && !_gridController) {
                [self showGrid:YES];
                return;
            } else if (!_startOnGrid && _gridController) {
                [self hideGrid:YES];
                return;
            }
        }
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - Layout
- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self layoutVisiblePages];
}

- (void)layoutVisiblePages {
    if (_currentViewer == nil) {
        if (_gridController) {
            [self hideGrid:NO];
        }
        [self performLayout];
    }
}

// MARK: - Data
- (void)reloadData {
    _photoCount = NSNotFound;
    
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [_photos removeAllObjects];
    [_thumbPhotos removeAllObjects];
    
    for (int i = 0; i < numberOfPhotos; i++) {
        [_photos addObject:[NSNull null]];
        [_thumbPhotos addObject:[NSNull null]];
    }
    
    if (numberOfPhotos > 0) {
        _currentPageIndex = MAX(0, MIN(_currentPageIndex, numberOfPhotos - 1));
    } else {
        _currentPageIndex = 0;
    }
    
    if ([self isViewLoaded]) {
        if (_currentViewer) {
            [_currentViewer.view removeFromSuperview];
            [_currentViewer removeFromParentViewController];
        }
        
        [self performLayout];
        [self.view setNeedsLayout];
    }
}

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        } else if (_fixedPhotosArray) {
            _photoCount = _fixedPhotosArray.count;
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (id<ZJPhotoProtocol>)photoAtIndex:(NSUInteger)index {
    id <ZJPhotoProtocol> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            } else if (_fixedPhotosArray && index < _fixedPhotosArray.count) {
                photo = [_fixedPhotosArray objectAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (id<ZJPhotoProtocol>)thumbPhotoAtIndex:(NSUInteger)index {
    id <ZJPhotoProtocol> photo = nil;
    if (index < _thumbPhotos.count) {
        if ([_thumbPhotos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:thumbPhotoAtIndex:)]) {
                photo = [_delegate photoBrowser:self thumbPhotoAtIndex:index];
            }
            if (photo) [_thumbPhotos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_thumbPhotos objectAtIndex:index];
        }
    }
    return photo;
}

- (UIImage *)imageForPhoto:(id<ZJPhotoProtocol>)photo {
    if (photo) {
        // Get image or obtain in background
        if ([photo underlyingImage]) {
            return [photo underlyingImage];
        } else {
            [photo loadUnderlyingImageAndNotify];
        }
    }
    return nil;
}

// MARK: - Grid
- (void)showGrid:(BOOL)animated {
    if (_gridController) {
        return;
    }
    
    _gridController = [[ZJGridViewController alloc] initWithFrame:self.view.bounds];
    _gridController.initialContentOffset = _gridController.collectionView.contentOffset;
    _gridController.browser = self;
    _gridController.view.frame = CGRectOffset(_gridController.view.frame, 0, (self.startOnGrid ? -1 : 1) * self.view.bounds.size.height);
    
    [self.view addSubview:_gridController.view];
    [self addChildViewController:_gridController];
    
    [_gridController.view layoutIfNeeded];
//    [_gridController adjustOffsetsAsRequired];
    
    [self updateNavigation];
    
    [_gridController willMoveToParentViewController:self];
    [UIView animateWithDuration:animated ? 0.3 : 0 animations:^{
        self.gridController.view.frame = self.view.bounds;
    } completion:^(BOOL finished) {
        [self.gridController didMoveToParentViewController:self];
    }];
}

- (void)hideGrid:(BOOL)animated {
    if (!_gridController) {
        return;
    }
    
    ZJGridViewController *tempGridController = _gridController;
    _gridController = nil;
    
    [self updateNavigation];
    
    [UIView animateWithDuration:animated ? 0.3 : 0 animations:^{
        tempGridController.view.frame = CGRectOffset(self.view.bounds, 0, (self.startOnGrid ? -1 : 1) * self.view.bounds.size.height);
    } completion:^(BOOL finished) {
        [tempGridController willMoveToParentViewController:self];
        [tempGridController.view removeFromSuperview];
        [tempGridController removeFromParentViewController];
    }];
}

#pragma mark - 监听方法
- (void)tapGesture {
//    _animator.fromImageView = _currentViewer.imageView;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)interactiveGesture:(UIGestureRecognizer *)recognizer {
    
    _statusBarHidden = (_currentViewer.scrollView.zoomScale > 1.0);
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (_statusBarHidden) {
        self.view.backgroundColor = _backgroundColor ? _backgroundColor : [UIColor blackColor];
        self.view.transform = CGAffineTransformIdentity;
        self.view.alpha = 1.0;
        _pageCountButton.hidden = ([self numberOfPhotos] == 1);
        
        return;
    }
    
    CGAffineTransform transfrom = self.view.transform;
    BOOL isRotation = NO;
    
    if ([recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
        UIPinchGestureRecognizer *pinch = (UIPinchGestureRecognizer *)recognizer;
        
        CGFloat scale = pinch.scale;
        transfrom = CGAffineTransformScale(transfrom, scale, scale);
        
        pinch.scale = 1.0;
    } else if ([recognizer isKindOfClass:[UIRotationGestureRecognizer class]]) {
        UIRotationGestureRecognizer *rotate = (UIRotationGestureRecognizer *)recognizer;
        
        CGFloat rotation = rotate.rotation;
        transfrom = CGAffineTransformRotate(transfrom, rotation);
        
        rotate.rotation = 0;
        isRotation = YES;
    }
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            _pageCountButton.hidden = YES;
            self.view.backgroundColor = _backgroundColor ? _backgroundColor : [UIColor clearColor];
            self.view.transform = transfrom;
//            self.view.alpha = transfrom.a;
            [self setButtonHidden:YES];
            
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
//            [self tapGesture];
            [self setButtonHidden:NO];

            if (isRotation) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.view.transform = CGAffineTransformIdentity;
//                    self.view.alpha = transfrom.a;
                } completion:^(BOOL finished) {
                    self.pageCountButton.hidden = ([self numberOfPhotos] == 1);
                }];
            }
        }
            break;
        default:
            break;
    }
}

- (void)longPressGesture:(UILongPressGestureRecognizer *)recognizer {
    
    if (recognizer.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if (_currentViewer.imageView.image == nil) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"保存至相册" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIImageWriteToSavedPhotosAlbum(self.currentViewer.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    NSString *message = (error == nil) ? @"保存成功" : @"保存失败";
    
    _messageLabel.text = message;
    
    [UIView
     animateWithDuration:0.7
     delay:0
     usingSpringWithDamping:0.8
     initialSpringVelocity:10
     options:0
     animations:^{
         self.messageLabel.transform = CGAffineTransformIdentity;
     } completion:^(BOOL finished) {
         [UIView animateWithDuration:0.5 animations:^{
             self.messageLabel.transform = CGAffineTransformMakeScale(0, 0);
         }];
     }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(ZJPhotoViewerController *)viewController {
    
    NSInteger index = viewController.photoIndex;
    
    if (index-- <= 0) {
        return nil;
    }
    
//    _currentPageIndex = index;
    return [self createViewerWithIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(ZJPhotoViewerController *)viewController {
    
    NSInteger index = viewController.photoIndex;
    
    if (++index >= [self numberOfPhotos]) {
        return nil;
    }
    
//    _currentPageIndex = index;
    return [self createViewerWithIndex:index];
}

- (ZJPhotoViewerController *)createViewerWithIndex:(NSInteger)currentPageIndex {
    ZJPhotoViewerController *viewer = [[ZJPhotoViewerController alloc] initWithPhotoBrowser:self photo:[self photoAtIndex:currentPageIndex] index:currentPageIndex];
//    [self configureViewer:viewer forIndex:_currentPageIndex];
    
    return viewer;
}

- (void)configureViewer:(ZJPhotoViewerController *)viewer forIndex:(NSUInteger)index {
    viewer.photoIndex = index;
    viewer.photo = [self photoAtIndex:index];
}

- (void)setCurrentPhotoIndex:(NSUInteger)index {
    NSUInteger photoCount = [self numberOfPhotos];
    if (photoCount == 0) {
        index = 0;
    } else {
        if (index >= photoCount) {
            index = [self numberOfPhotos] - 1;
        }
    }
    
    _currentPageIndex = index;
    if ([self isViewLoaded]) {
        [self jumpToCurrentPhotoIndexPage:NO];
    }
}

- (void)updateNavigation {
    // Title
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    if (_gridController) {
//        if (_gridController.selectionMode) {
//            self.title = NSLocalizedString(@"Select Photos", nil);
//        } else {
            NSString *photosText;
            if (numberOfPhotos == 1) {
                photosText = NSLocalizedString(@"item", @"Used in the context: '1 photo'");
            } else {
                photosText = NSLocalizedString(@"items", @"Used in the context: '3 photos'");
            }
            self.title = [NSString stringWithFormat:@"%lu %@", (unsigned long)numberOfPhotos, photosText];
//        }
    } else if (numberOfPhotos > 1) {
//        if ([_delegate respondsToSelector:@selector(photoBrowser:titleForPhotoAtIndex:)]) {
//            self.title = [_delegate photoBrowser:self titleForPhotoAtIndex:_currentPageIndex];
//        } else {
            self.title = [NSString stringWithFormat:@"%lu %@ %lu", (unsigned long)(_currentPageIndex+1), NSLocalizedString(@"of", @"Used in the context: 'Showing 1 of 3 items'"), (unsigned long)numberOfPhotos];
//        }
    } else {
        self.title = nil;
    }
}

- (void)jumpToCurrentPhotoIndexPage:(BOOL)animated {
    if (_currentViewer.photoIndex != _currentPageIndex) {
        [_currentViewer.view removeFromSuperview];
        [_currentViewer removeFromParentViewController];
        
        ZJPhotoViewerController *viewer = [self createViewerWithIndex:_currentPageIndex];
        [_pageController setViewControllers:@[viewer]
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:animated
                                 completion:nil];
        
        _currentViewer = viewer;
        
        [self setPageButtonIndex:viewer.photoIndex];
        [self updateNavigation];
    }
}

#pragma mark - UIPageViewControllerDelegate
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    ZJPhotoViewerController *viewer = pageViewController.viewControllers[0];
    
    _currentPageIndex = viewer.photoIndex;
    _currentViewer = viewer;
    
    [self setPageButtonIndex:viewer.photoIndex];
    [self updateNavigation];
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    [UIView animateWithDuration:0.25 animations:^{
        self.currentViewer.view.transform = CGAffineTransformIdentity;
    }];
}

- (void)setPageButtonIndex:(NSInteger)index {
    _pageCountButton.hidden = ([self numberOfPhotos] == 1);
    
    NSMutableAttributedString *attributeText = [[NSMutableAttributedString alloc]
                                                initWithString:[NSString stringWithFormat:@"%zd", index + 1]
                                                attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:18],
                                                             NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [attributeText appendAttributedString:[[NSAttributedString alloc]
                                           initWithString:[NSString stringWithFormat:@" / %zd", [self numberOfPhotos]]
                                           attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14],
                                                        NSForegroundColorAttributeName: [UIColor whiteColor]}]];
    [_pageCountButton setAttributedTitle:attributeText forState:UIControlStateNormal];
}

- (void)deletePhoto:(UIButton *)sender {
    NSLog(@">>>>>> deletePhoto ");
    
    id <ZJPhotoProtocol> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            if (_popController.popoverVisible) {return;}
            UIViewController *vc = [[UIViewController alloc] init];
            UIButton *testButton = [[UIButton alloc] initWithFrame:CGRectMake(5.0f, 5.0f, 260.0f, 47.0f)];
            [testButton setTitle:NSLocalizedString(@"SureDelete", @"") forState:UIControlStateNormal];
            [testButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
            [testButton addTarget:self action:@selector(deleteDetail) forControlEvents:UIControlEventTouchUpInside];
            [vc.view addSubview:testButton];
            
            UIPopoverController *popController = [[UIPopoverController alloc] initWithContentViewController:vc];
            popController.popoverContentSize = CGSizeMake(270.0f, 67.0f);
            _popController = popController;
            [_popController presentPopoverFromBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:_deleteButton]
                                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                                   animated:YES];
        } else {
            _actionsSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")  style:UIAlertActionStyleCancel handler:nil]];
            [_actionsSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"SureDelete", @"") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self deleteDetail];
            }]];
            
            [self presentViewController:_actionsSheet animated:YES completion:nil];
        }
    }
}

- (void)sharePhoto:(UIButton *)sender {
    NSLog(@">>>>>>>> sharePhoto");
    [self sharePhotoAction];
}

// MARK: - Action
- (void)sharePhotoAction {
    id <ZJPhotoProtocol> photo = [self photoAtIndex:_currentPageIndex];
    
    if ([self numberOfPhotos] > 0 && [photo underlyingImage]) {
        [SVProgressHUD show];
        
        if (photo.isVideo) {
            if ([photo respondsToSelector:@selector(getVideoURL:)]) {
                // Get video
                [photo getVideoURL:^(NSURL *url) {
                    [self shareActionDetail:photo obj:url];
                }];
            }
        } else {
            [self shareActionDetail:photo obj:[photo underlyingImage]];
        }
    }
}

- (void)shareActionDetail:(id <ZJPhotoProtocol>)photo obj:(id)obj {
    // Show activity view controller
    NSMutableArray *items = [NSMutableArray array];
    if (obj) {
        [items addObject:obj];
    }
    
    if (photo) {
        [items addObject:photo];
    }
    
    self.activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    // Show loading spinner after a couple of seconds
    double delayInSeconds = 0.5; // change 2.0s to 0.5s, To showProgressHUDCompleteMessage after saved
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.activityViewController) {
            
        }
    });
    
    // Show
    typeof(self) __weak weakSelf = self;
    [self.activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        weakSelf.activityViewController = nil;
    }];
    
    // iOS 8 - Set the Anchor Point for the popover
    if ([[[UIDevice currentDevice] systemVersion] compare:@"8" options:NSNumericSearch] != NSOrderedAscending) {
        self.activityViewController.popoverPresentationController.barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_shareButton];
    }
    
    [self presentViewController:self.activityViewController animated:YES completion:^{
        [SVProgressHUD dismiss];
    }];
}

- (void)deleteDetail
{
    id <ZJPhotoProtocol> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [_popController dismissPopoverAnimated:YES];
        // Buttons
//        _shareButton.enabled = NO;
//        _deleteButton.enabled = NO;
        
        [SVProgressHUD showWithStatus:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"Deleting", @"Displayed with ellipsis as 'Deleting...' when an item is in the process of being copied")]];
        //[self performSelector:@selector(actuallyDeletePhoto:) withObject:photo afterDelay:0];
        [self performSelectorInBackground:@selector(actuallyDeletePhoto:) withObject:photo];
    }
}

- (void)actuallyDeletePhoto:(id<ZJPhotoProtocol>)photo {
    if ([photo underlyingImage]) {
        if([_delegate respondsToSelector:@selector(photoBrowser:deletePhotoAtIndex:completionHandler:)]) {
            [self.delegate photoBrowser:self deletePhotoAtIndex:_currentPageIndex completionHandler:^(BOOL success) {
                if (success) {
                    [self performSelectorOnMainThread:@selector(deleteSucceed) withObject:nil waitUntilDone:NO];
                } else {
                    [self performSelectorOnMainThread:@selector(deleteFailed) withObject:nil waitUntilDone:NO];
                }
            }];
//            if (![self.delegate photoBrowser:self deletePhotoAtIndex:_currentPageIndex]) {
//                [self performSelectorOnMainThread:@selector(deleteFailed) withObject:nil waitUntilDone:NO];
//            } else {
//                [self performSelectorOnMainThread:@selector(deleteSucceed) withObject:nil waitUntilDone:NO];
//            }
        }
    }
}

- (void)deleteSucceed
{
    if (_photoCount > 1) {
        [self reloadData];
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Deleted", @"Informing the user an item has finished deleting")];
    } else {
        [SVProgressHUD dismiss];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)deleteFailed
{
    [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"DeleteError", nil)];
}

#pragma mark - 设置界面
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = backgroundColor;
    self.view.backgroundColor = backgroundColor;
}

- (void)prepareUI {
    self.view.backgroundColor = [UIColor blackColor];
    
    // 分页控制器
    UIPageViewController *pageController = [[UIPageViewController alloc]
                                            initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                            navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                            options:@{UIPageViewControllerOptionInterPageSpacingKey: @20}];
    pageController.dataSource = self;
    pageController.delegate = self;
    
    ZJPhotoViewerController *viewer = [self createViewerWithIndex:_currentPageIndex];
    [pageController setViewControllers:@[viewer]
                             direction:UIPageViewControllerNavigationDirectionForward
                              animated:YES
                            completion:nil];
    
    [self.view addSubview:pageController.view];
    [self addChildViewController:pageController];
    [pageController didMoveToParentViewController:self];
    
    _currentViewer = viewer;
    _pageController = pageController;
    
#if 0
    // 手势识别
    self.view.gestureRecognizers = pageController.gestureRecognizers;
    
//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture)];
//    [self.view addGestureRecognizer:tap];
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveGesture:)];
    [self.view addGestureRecognizer:pinch];
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveGesture:)];
    [self.view addGestureRecognizer:rotate];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self.view addGestureRecognizer:longPress];
    
    pinch.delegate = self;
    rotate.delegate = self;
#endif
    
    // 分页按钮
    /*
    _pageCountButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 80, 40)];
    CGPoint center = self.view.center;
    center.y = _pageCountButton.bounds.size.height + 64;
    _pageCountButton.center = center;
    
    _pageCountButton.layer.cornerRadius = 6;
    _pageCountButton.layer.masksToBounds = YES;
    
    _pageCountButton.backgroundColor = [UIColor colorWithWhite:0.6 alpha:0.6];
    [self setPageButtonIndex:_currentPageIndex];
    [self.view addSubview:_pageCountButton];
     */
    
    // 提示标签
    _messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 60)];
    _messageLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    _messageLabel.textColor = [UIColor whiteColor];
    _messageLabel.textAlignment = NSTextAlignmentCenter;
    _messageLabel.layer.cornerRadius = 6;
    _messageLabel.layer.masksToBounds = YES;
    _messageLabel.transform = CGAffineTransformMakeScale(0, 0);
    
    _messageLabel.center = self.view.center;
    [self.view addSubview:_messageLabel];
    
    [self addDeleteButton];
    [self addShareButton];
    [self customizationSVProgressHUD];
}

- (void)customizationSVProgressHUD {
    [SVProgressHUD setDefaultStyle:SVProgressHUDStyleDark];
    [SVProgressHUD setDefaultAnimationType:SVProgressHUDAnimationTypeNative];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setMinimumDismissTimeInterval:2.0];
}

- (void)addDeleteButton {
    UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    CGPoint center = self.view.center;
    center.y = self.view.bounds.size.height - deleteButton.bounds.size.height;
    center.x -= deleteButton.bounds.size.width;
    deleteButton.center = center;
    
    deleteButton.layer.cornerRadius = deleteButton.bounds.size.height * 0.5;
    deleteButton.layer.masksToBounds = YES;
//    deleteButton.backgroundColor = [UIColor orangeColor];
//    [deleteButton setTitle:@"Delete" forState:UIControlStateNormal];
    [deleteButton setImage:[UIImage imageNamed:@"btn-delect"] forState:UIControlStateNormal];
    [deleteButton setImage:[UIImage imageNamed:@"btn-delect-pre"] forState:UIControlStateHighlighted];
    [deleteButton addTarget:self action:@selector(deletePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:deleteButton];
    _deleteButton = deleteButton;
    [deleteButton sizeToFit];
}

- (void)addShareButton {
    UIButton *shareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
    CGPoint center = self.view.center;
    center.x += shareButton.bounds.size.width;
    center.y = self.view.bounds.size.height - shareButton.bounds.size.height;
    shareButton.center = center;
    
    shareButton.layer.cornerRadius = shareButton.bounds.size.height * 0.5;
    shareButton.layer.masksToBounds = YES;
//    shareButton.backgroundColor = [UIColor orangeColor];
//    [shareButton setTitle:@"Share" forState:UIControlStateNormal];
    [shareButton setImage:[UIImage imageNamed:@"btn-delect-share"] forState:UIControlStateNormal];
    [shareButton setImage:[UIImage imageNamed:@"btn-share-pre"] forState:UIControlStateHighlighted];
    [shareButton addTarget:self action:@selector(sharePhoto:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:shareButton];
    _shareButton = shareButton;
    [shareButton sizeToFit];
}

// MARK: Rotation
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self setButtonHidden:(size.width > size.height)];
}

- (void)setButtonHidden:(BOOL)hide {
    _shareButton.hidden = hide;
    _deleteButton.hidden = hide;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
