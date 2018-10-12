//
//  ZJPhotoViewerController.m
//  ZJPhotoBrowserTest
//
//  Created by ZJ on 2018/5/29.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "ZJPhotoViewerController.h"
#import "ZJPhotoBrowserController.h"
#import "Extensions/UIImage+ZJPhotoBrowser.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVKit/AVKit.h>

@interface ZJPhotoViewerController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, AVPlayerViewControllerDelegate>

@property (nonatomic, weak) ZJPhotoBrowserController *photoBrowser;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImage *placeholder;
@property (nonatomic, strong) UIButton *videoIndicator;
@property (nonatomic, strong) MPMoviePlayerViewController *currentVideoPlayerViewController;
@property (nonatomic, strong) UIActivityIndicatorView *currentVideoLoadingIndicator;
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, assign) BOOL isRotationGesture;
@property (nonatomic, strong) AVPlayerViewController *currentAVPlayerViewController;


@end

@implementation ZJPhotoViewerController

- (instancetype)initWithPhotoBrowser:(ZJPhotoBrowserController *)browser photo:(ZJPhoto *)photo index:(NSUInteger)index
{
    self = [super init];
    if (self) {
        _photoBrowser = browser;
        _photo = photo;
        _photoIndex = index;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                     name:kZJPhotoLoadingDidEndNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self prepareUI];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self displayImage];
    [self setVideoIndicatorState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [self clearCurrentVideo];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setPhoto:(id<ZJPhotoProtocol>)photo {
    _photo = photo;
    
    UIImage *image = [_photoBrowser imageForPhoto:photo];
    if (image) {
        [self displayImage];
    }
}

- (void)setVideoIndicatorState {
    if (_photo) {
        if ([_photo respondsToSelector:@selector(isVideo)]) {
            _videoIndicator.hidden = !_photo.isVideo;
        } else {
            _videoIndicator.hidden = YES;
        }
    }
}

- (void)displayImage {
    if (_photo) {
        UIImage *image = [_photoBrowser imageForPhoto:_photo];
        
        if (image) {
            _imageView.image = image;
            
//            [self setImagePosition:image];
            [self layoutSubviews:[UIScreen mainScreen].bounds.size];
        } else {
            [self displayImageFailure];
        }
        
        [self.scrollView setNeedsLayout];
    }
}

- (void)displayImageFailure {
    
}

- (void)setImagePosition:(UIImage *)image {
    CGSize size = [self imageSizeWithScreen:image];

    _imageView.frame = CGRectMake(0, 0, size.width, size.height);
    _scrollView.contentSize = size;

    if (size.height < _scrollView.bounds.size.height) {
        CGFloat offsetY = (_scrollView.bounds.size.height - size.height) * 0.5;

        _scrollView.contentInset = UIEdgeInsetsMake(offsetY, 0, offsetY, 0);
    }
}

- (CGSize)imageSizeWithScreen:(UIImage *)image {
    CGSize size = [UIScreen mainScreen].bounds.size;
    size.height = image.size.height * size.width / image.size.width;
    
    return size;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return _imageView;
}

// MARK: - Video
- (void)playVideo:(id)sender {
    if (!_currentVideoPlayerViewController) {
        if ([_photo respondsToSelector:@selector(getVideoURL:)]) {
            
            // Valid for playing
            [self clearCurrentVideo];
            [self setVideoLoadingIndicatorVisible:YES atPageIndex:0];
            
            // Get video and play
            [_photo getVideoURL:^(NSURL *url) {
                if (url) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self _playVideo:url];
//                        [self playVideoHandler:url];
                    });
                } else {
                    [self setVideoLoadingIndicatorVisible:NO atPageIndex:0];
                }
            }];
            
        }
    }
}

- (void)playVideoHandler:(NSURL *)videoURL {
    AVPlayer *avPlayer = [AVPlayer playerWithURL:videoURL];
    _currentAVPlayerViewController = [[AVPlayerViewController alloc] init];
    _currentAVPlayerViewController.player = avPlayer;
    _currentAVPlayerViewController.videoGravity = AVLayerVideoGravityResizeAspect;
    _currentAVPlayerViewController.showsPlaybackControls = YES;
    _currentAVPlayerViewController.view.frame = self.view.bounds;
    _currentAVPlayerViewController.delegate = self;

//    [self addChildViewController:_currentAVPlayerViewController];
//    [self.view addSubview:_currentAVPlayerViewController.view];
//    [_currentAVPlayerViewController.player play];
    
    [self presentViewController:_currentAVPlayerViewController animated:YES completion:^{
        [_currentAVPlayerViewController.player play];
    }];
}

- (void)_playVideo:(NSURL *)videoURL {
    
    // Setup player
    _currentVideoPlayerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:videoURL];
    [_currentVideoPlayerViewController.moviePlayer prepareToPlay];
    _currentVideoPlayerViewController.moviePlayer.shouldAutoplay = YES;
    _currentVideoPlayerViewController.moviePlayer.scalingMode = MPMovieScalingModeAspectFit;
    _currentVideoPlayerViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    // Remove the movie player view controller from the "playback did finish" notification observers
    // Observe ourselves so we can get it to use the crossfade transition
    [[NSNotificationCenter defaultCenter] removeObserver:_currentVideoPlayerViewController
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoFinishedCallback:)
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
                                               object:_currentVideoPlayerViewController.moviePlayer];
    
    // Show
    [self presentViewController:_currentVideoPlayerViewController animated:YES completion:nil];
    
}

- (void)videoFinishedCallback:(NSNotification*)notification {
    
    // Remove observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:_currentVideoPlayerViewController.moviePlayer];
    
    // Clear up
    [self clearCurrentVideo];
    
    // Dismiss
    BOOL error = [[[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] intValue] == MPMovieFinishReasonPlaybackError;
    if (error) {
        // Error occured so dismiss with a delay incase error was immediate and we need to wait to dismiss the VC
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.photoBrowser.currentViewer = nil;
            [self dismissViewControllerAnimated:YES completion:nil];
        });
    } else {
        self.photoBrowser.currentViewer = nil;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)clearCurrentVideo {
    if (!_currentVideoPlayerViewController) return;
    [_currentVideoLoadingIndicator removeFromSuperview];
    _currentVideoPlayerViewController = nil;
    _currentVideoLoadingIndicator = nil;
}

- (void)setVideoLoadingIndicatorVisible:(BOOL)visible atPageIndex:(NSUInteger)pageIndex {
    if (_currentVideoLoadingIndicator && !visible) {
        [_currentVideoLoadingIndicator removeFromSuperview];
        _currentVideoLoadingIndicator = nil;
    } else if (!_currentVideoLoadingIndicator && visible) {
        _currentVideoLoadingIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
        [_currentVideoLoadingIndicator sizeToFit];
        [_currentVideoLoadingIndicator startAnimating];
        [_scrollView addSubview:_currentVideoLoadingIndicator];
        [self positionVideoLoadingIndicator];
    }
}

- (void)positionVideoLoadingIndicator {
    if (_currentVideoLoadingIndicator) {
        CGRect frame = _scrollView.bounds;
        _currentVideoLoadingIndicator.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    }
}

// MARK: - setup GUI
- (void)prepareUI {
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_scrollView];
    _scrollView.scrollEnabled = NO;
    _scrollView.backgroundColor = [UIColor whiteColor];
    
    _imageView = [[UIImageView alloc] initWithImage:_placeholder];
    _imageView.center = self.view.center;
    [_scrollView addSubview:_imageView];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.minimumZoomScale = 1.0;
    _scrollView.delegate = self;
    
    [self addVideoIndicator];
    [self addGestureRecognizer];
}

- (void)addVideoIndicator {
    _videoIndicator = [UIButton new];
    _videoIndicator.hidden = YES;
    UIImage *videoIndicatorImage = [UIImage imageForResourcePath:@"ZJPhotoBrowser.bundle/icons/home-btn-play"/*@"ZJPhotoBrowser.bundle/icons/PlayButtonOverlayLarge"*/ ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
    _videoIndicator.frame = CGRectMake(0, 0, videoIndicatorImage.size.width * UIScreen.mainScreen.scale, videoIndicatorImage.size.height * UIScreen.mainScreen.scale);
    [_videoIndicator setImage:videoIndicatorImage forState:UIControlStateNormal];
    [_videoIndicator setImage:[UIImage imageForResourcePath:@"ZJPhotoBrowser.bundle/icons/home-btn-play"/*@"ZJPhotoBrowser.bundle/images/PlayButtonOverlayLargeTap"*/ ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateHighlighted];
    _videoIndicator.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [_videoIndicator addTarget:self action:@selector(playVideo:) forControlEvents:UIControlEventTouchUpInside];

    [self.imageView addSubview:_videoIndicator];
    _imageView.userInteractionEnabled = YES;
    [_videoIndicator sizeToFit];
}

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <ZJPhotoProtocol> photo = [notification object];
    if (photo == _photo) {
        if ([photo underlyingImage]) {
            // Successful load
            [self displayImage];
        } else {
            // Failed to load
            //            [self showImageFailure];
        }
        //        [self hideLoadingIndicator];
    }
}

- (void)layoutSubviews:(CGSize)size {
    _scrollView.frame = CGRectMake(0, 0, size.width, size.height);

    BOOL isLandscape = size.width > size.height;
    
    CGSize contentSize = size;
    UIImage *image = [_photoBrowser imageForPhoto:_photo];
    if (image) {
        if (isLandscape) {
            contentSize.width = image.size.width * contentSize.height / image.size.height;
        } else {
            contentSize.height = image.size.height * contentSize.width / image.size.width;
        }
    }
    
    _scrollView.contentSize = contentSize;
    _imageView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
    _videoIndicator.center = self.imageView.center;

    if (isLandscape) {
        // L
        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _imageView.center = _scrollView.center;
    } else {
        // p
        if (contentSize.height < _scrollView.bounds.size.height) {
            CGFloat offsetY = (_scrollView.bounds.size.height - contentSize.height) * 0.5;
            
            _scrollView.contentInset = UIEdgeInsetsMake(offsetY, 0, offsetY, 0);
        }
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
//    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//        // before
//    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//        // after
//    }];
    
//    BOOL isLandscape = size.width > size.height;
//
//    _scrollView.frame = CGRectMake(0, 0, size.width, size.height);
//
//    CGSize contentSize = size;
//    UIImage *image = [_photoBrowser imageForPhoto:_photo];
//    if (image) {
//        if (isLandscape) {
//            contentSize.width = image.size.width * contentSize.height / image.size.height;
//        } else {
//            contentSize.height = image.size.height * contentSize.width / image.size.width;
//        }
//    }
//
//    if (isLandscape) {
//        // L
//        _scrollView.contentSize = contentSize;
//        _scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
//        _imageView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
//        _imageView.center = _scrollView.center;
//    } else {
//        // p
//        _imageView.frame = CGRectMake(0, 0, contentSize.width, contentSize.height);
//        _scrollView.contentSize = contentSize;
//
//        if (contentSize.height < _scrollView.bounds.size.height) {
//            CGFloat offsetY = (_scrollView.bounds.size.height - contentSize.height) * 0.5;
//
//            _scrollView.contentInset = UIEdgeInsetsMake(offsetY, 0, offsetY, 0);
//        }
//    }
    [self layoutSubviews:size];
    self.view.transform = CGAffineTransformIdentity;
}

- (void)addGestureRecognizer {
#if 0
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.numberOfTouchesRequired  = 1;
    [self.view addGestureRecognizer:singleTapGesture];
#endif
    
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:doubleTapGesture];

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveGesture:)];
    [self.view addGestureRecognizer:pinch];
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(interactiveGesture:)];
    [self.view addGestureRecognizer:rotate];
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGesture:)];
    [self.view addGestureRecognizer:longPress];
    
    pinch.delegate = self;
    rotate.delegate = self;
}

#pragma mark - 监听方法
- (void)tapGesture {
    //    _animator.fromImageView = _currentViewer.imageView;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleDoubleTap:(UIGestureRecognizer *)sender {
    UIView *view = [sender view];
    if (view.tag == 0) {
        view.tag = 1;

        [UIView animateWithDuration:0.3 animations:^{
            self.view.transform = CGAffineTransformScale(self.view.transform, 2, 2);
        }];
    } else {
        view.tag = 0;

        [UIView animateWithDuration:0.3 animations:^{
            self.view.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)interactiveGesture:(UIGestureRecognizer *)recognizer {
    
    _statusBarHidden = (_scrollView.zoomScale > 1.0);
    [self setNeedsStatusBarAppearanceUpdate];
    
    if (_statusBarHidden) {
        self.view.backgroundColor = [UIColor whiteColor];
        self.view.transform = CGAffineTransformIdentity;
        self.view.alpha = 1.0;
        
        return;
    }
    
    CGAffineTransform transfrom = self.view.transform;
    
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
        _isRotationGesture = YES;
    }
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        case UIGestureRecognizerStateChanged:
            self.view.backgroundColor = [UIColor clearColor];
            self.view.transform = transfrom;
//            self.view.alpha = transfrom.a;
            
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded: {
//            [self tapGesture];
            
            if (_isRotationGesture) {
                [UIView animateWithDuration:0.3 animations:^{
                    self.view.transform = CGAffineTransformIdentity;
//                    self.view.alpha = transfrom.a;
                } completion:^(BOOL finished) {
                }];
                
                _isRotationGesture = NO;
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
    if (_imageView.image == nil) {
        return;
    }
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Save to Album"/*@"保存至相册"*/ style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel"/*@"取消"*/ style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
//    NSString *message = (error == nil) ? @"保存成功" : @"保存失败";
//
//    _messageLabel.text = message;
//
//    [UIView
//     animateWithDuration:0.7
//     delay:0
//     usingSpringWithDamping:0.8
//     initialSpringVelocity:10
//     options:0
//     animations:^{
//         self.messageLabel.transform = CGAffineTransformIdentity;
//     } completion:^(BOOL finished) {
//         [UIView animateWithDuration:0.5 animations:^{
//             self.messageLabel.transform = CGAffineTransformMakeScale(0, 0);
//         }];
//     }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - AVPlayerViewControllerDelegate
- (void)playerViewControllerWillStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    SHLogTRACE();
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    SHLogTRACE();
}

@end
