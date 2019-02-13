// SHWechatServerVC.m

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
 
 // Created by zj on 2019/1/31 2:05 PM.
    

#import "SHWechatServerVC.h"
#import "SHWCQRCodeView.h"
#import "SHWCConcernView.h"
#import "SHWCServerView.h"
#import "SVProgressHUD.h"

static const NSUInteger kPages = 2;

@interface SHWechatServerVC () <UIScrollViewDelegate, SHWCQRCodeViewDelegate, SHWCConcernViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) SHWCQRCodeView *wcqrcodeView;
@property (nonatomic, strong) SHWCConcernView *wcconcernView;
@property (nonatomic, weak) UIPageControl *pageControl;
@property (nonatomic, strong) SHWCServerView *wcserverView;

@property (nonatomic, assign, getter=isConcern) BOOL concern;

@end

@implementation SHWechatServerVC

+ (instancetype)wechatServerVC {
    return [[self alloc] init];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
//    self.concern = YES;
    
    [self setupGUI];
}

//- (void)viewWillLayoutSubviews {
//    [super viewWillLayoutSubviews];
//    [self performLayout];
//}

- (void)setupGUI {
    self.view.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
    [self setupNavigationGUI];
    
    [SVProgressHUD showWithStatus:@"正在努力加载..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD setContainerView:self.view];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        [NSThread sleepForTimeInterval:2.0];
        
        self.concern = arc4random_uniform(2);
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [SVProgressHUD dismiss];
            self.isConcern ? [self setupConcernedGUI] : [self setupNotConcernGUI];
        }];
    }];
}

- (void)setupConcernedGUI {
    [self.view addSubview:self.wcserverView];
}

- (void)setupNotConcernGUI {
    [self setupScrollView];
    [self setupScrollViewSubViews];
    [self setupPageControl];
}

- (void)setupNavigationGUI {
    self.title = @"公众号服务";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:nil fontSize:16.0 image:[UIImage imageNamed:@"nav-btn-cancel"] target:self action:@selector(close) isBack:NO];
}

- (void)close {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupScrollView {
    self.scrollView = [[UIScrollView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    [self.view addSubview:self.scrollView];
    
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bounces = NO;
    self.scrollView.scrollEnabled = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.scrollView.delegate = self;
}

- (void)setupScrollViewSubViews {
    CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
//    CGFloat height = CGRectGetHeight([UIScreen mainScreen].bounds);
    
    self.scrollView.contentSize = CGSizeMake(width * kPages, 0);
    
    [self.scrollView addSubview:self.wcqrcodeView];
    self.wcqrcodeView.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
    
    self.wcconcernView.frame = CGRectOffset(self.wcconcernView.frame, width, 0); //CGRectMake(width, 0, width, height);
    [self.scrollView addSubview:self.wcconcernView];
    self.wcconcernView.backgroundColor = [UIColor ic_colorWithHex:kBackgroundThemeColor];
}

- (void)performLayout {
    if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
        UINavigationBar *navBar = self.navigationController.navigationBar;
        self.scrollView.contentInset = UIEdgeInsetsMake(navBar.frame.origin.y + navBar.frame.size.height, 0, 0, 0);
    }
}

- (void)setupPageControl {
    CGFloat width = 50;
    CGFloat height = 20;
    CGFloat margin = 10;
    CGFloat x = (UIScreen.screenWidth - width) * 0.5;
    CGFloat y = UIScreen.screenHeight - height - margin;
    
    UIPageControl *pageControl = [[UIPageControl alloc] init];

    pageControl.frame = CGRectMake(x, y, width, height);
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor ic_colorWithHex:kThemeColor];
    pageControl.numberOfPages = kPages;
    pageControl.currentPage = 0;
    
    self.pageControl = pageControl;
    
    [self.view addSubview:pageControl];
    [self.view bringSubviewToFront:pageControl];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    offsetX += CGRectGetWidth(scrollView.frame) * 0.5;
    
    NSInteger page = offsetX / CGRectGetWidth(scrollView.frame);
    
    self.pageControl.currentPage = page;
}

#pragma mark - SHWCQRCodeViewDelegate
- (void)saveQRCodeClicked:(SHWCQRCodeView *)qrcodeView {
    CGFloat offsetX = (self.pageControl.currentPage + 1) * CGRectGetWidth(self.scrollView.frame);
    [self.scrollView setContentOffset:CGPointMake(offsetX, 0) animated:YES];
}

#pragma mark - SHWCConcernViewDelegate
- (void)openWeChatHandle:(SHWCConcernView *)concernView {
    [self openWeChatHandler];
}

- (void)openWeChatHandler {
    NSURL *url = [NSURL URLWithString:@"weixin://"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        [self showNotOpenWeChatAlertView];
    }
}

- (void)showNotOpenWeChatAlertView {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"您没有安装手机微信，请安装手机微信后重试，谢谢！" preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

#pragma mark - init
- (SHWCQRCodeView *)wcqrcodeView {
    if (_wcqrcodeView == nil) {
        _wcqrcodeView = [SHWCQRCodeView wcqrcodeView];
        _wcqrcodeView.delegate = self;
    }
    
    return _wcqrcodeView;
}

- (SHWCConcernView *)wcconcernView {
    if (_wcconcernView == nil) {
        _wcconcernView = [SHWCConcernView wcconcernView];
        _wcconcernView.delegate = self;
    }
    
    return _wcconcernView;
}

- (SHWCServerView *)wcserverView {
    if (_wcserverView == nil) {
        _wcserverView = [SHWCServerView wcserverView];
    }
    
    return _wcserverView;
}

@end
