//
//  SHLocalAlbumCell.m
//  SmartHome
//
//  Created by ZJ on 2017/7/27.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHLocalAlbumCell.h"
#import "SDImageCache.h"
#import "MWCommon.h"
#import "MWPhotoBrowser.h"
#import "ZJPhotoBrowserController.h"

@interface SHLocalAlbumCell() <MWPhotoBrowserDelegate, ZJPhotoBrowserControllerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *thumnailButton;
@property (weak, nonatomic) IBOutlet UIButton *iconButton;
@property (weak, nonatomic) IBOutlet UILabel *mediaTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *mediaCountLabel;
@property (weak, nonatomic) IBOutlet UIImageView *iconBackImgView;
@property (weak, nonatomic) IBOutlet UIImageView *thumnailImgView;

- (IBAction)enterMediaStore:(UIButton *)sender;


@property(nonatomic) UIButton *selectSender;
@property(nonatomic, strong) NSMutableArray *photos;
@property(nonatomic, strong) NSMutableArray *thumbs;
@property(nonatomic) NSMutableArray *selections;



@end

@implementation SHLocalAlbumCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    _thumnailImgView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
-(void)setHighlightBackgroud {
    NSLog(@"highlight---");
    if(_mediaType) {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-video-pre"]];
    } else {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-photo-pre"]];
    }
    _mediaTypeLabel.textColor = [UIColor whiteColor];
    _mediaCountLabel.textColor = [UIColor whiteColor];
}
-(void)setNormalBackground {
    NSLog(@"normal---");
    _mediaTypeLabel.textColor = [UIColor blackColor];
    _mediaCountLabel.textColor = [UIColor blackColor];
    if(_mediaType) {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-video"]];
    } else {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-photo"]];
    }
}

- (void)setAssetsArray:(NSArray *)assetsArray {
    _assetsArray = assetsArray;
    
    NSArray *photoAssets = assetsArray;
    UIImage *image = nil;
    NSString *typeStr = nil;
    
    if (photoAssets.count) {
        if(_mediaType) {
            [self updateVideoThumnailWithAsset:photoAssets[0]];
        } else {
            [self updatePhotoThumnailWithAsset:photoAssets[0]];
        }
        
    } else {
        NSString *imageName = @"camera roll-btn-photo-loading";
        if (_mediaType) {
            imageName = @"camera roll-btn-video-loading";
        }
        
        image = [UIImage imageNamed:imageName];

        [_thumnailImgView setImage:image];
    }
    
    if(_mediaType) {
        typeStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Videos", nil)];
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-video"]];
    } else {
       typeStr = [NSString stringWithFormat:@"%@", NSLocalizedString(@"PhotosLabel", nil)];
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-photo"]];
    }
    [_iconButton addTarget:self action:@selector(setHighlightBackgroud) forControlEvents:UIControlEventTouchDown];
    [_iconButton addTarget:self action:@selector(setNormalBackground) forControlEvents:UIControlEventTouchUpInside];
    
    [_thumnailButton addTarget:self action:@selector(setHighlightBackgroud) forControlEvents:UIControlEventTouchDown];
    [_thumnailButton addTarget:self action:@selector(setNormalBackground) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *countStr = [NSString stringWithFormat:@"(%zd)", photoAssets.count];
//    [_thumnailImgView setImage:image];
    _mediaTypeLabel.text = [NSString stringWithFormat:@"%@", typeStr];
    _mediaCountLabel.text = [NSString stringWithFormat:@"%@", countStr];
    self.userInteractionEnabled = photoAssets.count;
}

- (void)updatePhotoThumnailWithAsset:(PHAsset *)asset {
    PHCachingImageManager *manager = (PHCachingImageManager *)[PHCachingImageManager defaultManager]; //[[PHCachingImageManager alloc] init];
    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    
    [manager requestImageForAsset:asset
                       targetSize:_thumnailImgView.frame.size
                      contentMode:PHImageContentModeAspectFit
                          options:options
                    resultHandler:^(UIImage *result, NSDictionary *info) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIImage *image = [UIImage imageNamed:@"camera roll-btn-photo-loading"];
                            SHLogInfo(SHLogTagAPP, @"photo thumnail: %@", result);

                            if (result) {
                                image = result;
                            }
                            
                            _thumnailImgView.image = image;
                        });
                        
                    }];
}

- (void)updateVideoThumnailWithAsset:(PHAsset *)asset {
    PHCachingImageManager *manager = (PHCachingImageManager *)[PHCachingImageManager defaultManager]; //[[PHCachingImageManager alloc] init];
    PHImageRequestOptions * options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    [manager requestImageForAsset:asset
                       targetSize:_thumnailImgView.frame.size
                      contentMode:PHImageContentModeAspectFit
                          options:options
                    resultHandler:^(UIImage *result, NSDictionary *info) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            UIImage *image = [UIImage imageNamed:@"camera roll-btn-video-loading"];
                            SHLogInfo(SHLogTagAPP, @"video thumnail: %@", result);

                            if (result) {
                                image = result;
                            }
                            
                            _thumnailImgView.image = image;
                        });
                        
                    }];
}

- (UIImage *)getImage:(NSURL *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 300);
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return thumb;
}

- (IBAction)showLocalMediaBrowser:(UIButton *)sender {
    [self enterPhotoBrowser];
}

#pragma mark - MWPhotoBrowserDelegate

// use new photoBrowser
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser didDisplayPhotoAtIndex:(NSUInteger)index {
    NSLog(@"Did start viewing photo at index %lu", (unsigned long)index);
}

- (BOOL)photoBrowser:(MWPhotoBrowser *)photoBrowser isPhotoSelectedAtIndex:(NSUInteger)index {
    return [[_selections objectAtIndex:index] boolValue];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index selectedChanged:(BOOL)selected {
    [_selections replaceObjectAtIndex:index withObject:[NSNumber numberWithBool:selected]];
    NSLog(@"Photo at index %lu selected %@", (unsigned long)index, selected ? @"YES" : @"NO");
}

// use new photoBrowser
- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser shareImageAtIndex:(NSUInteger)index{
	//share...
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser cameraDisconnectHandle:(NSNotification *)notification {
    SHCameraObject *shCamObj = notification.object;
    if (!shCamObj.isConnect) {
        return;
    }
    
    if (shCamObj.controler.actCtrl.isRecord) {
        [shCamObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
    }
    if (shCamObj.streamOper.PVRun) {
        [shCamObj.streamOper stopMediaStreamWithComplete:^{
            [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }];
    } else {
        [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
    }
    
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"kDisconnect", nil)] message:NSLocalizedString(@"kDisconnectTipsInfo", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [photoBrowser presentViewController:alertVc animated:YES completion:nil];
}

- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser cameraPowerOffHandle:(NSNotification *)notification {
    SHCameraObject *shCamObj = notification.object;
    [shCamObj.sdk disableTutk];
    
    if (shCamObj.controler.actCtrl.isRecord) {
        [shCamObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
    }
    
    if (shCamObj.streamOper.PVRun) {
        [shCamObj.streamOper stopMediaStreamWithComplete:^{
            [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
        }];
    } else {
        [shCamObj disConnectWithSuccessBlock:nil failedBlock:nil];
    }
    
    NSDictionary *userInfo = notification.userInfo;
    int value = [userInfo[kPowerOffEventValue] intValue];
    NSString *tipsInfo = NSLocalizedString(@"kCameraPowerOff", nil);
    if (value == 1) {
        tipsInfo = NSLocalizedString(@"kCameraPowerOffByRemoveSDCard", nil);
    }
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:[NSString stringWithFormat:@"[%@] %@", shCamObj.camera.cameraName, tipsInfo] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [photoBrowser presentViewController:alertC animated:YES completion:nil];
}

- (IBAction)enterMediaStore:(UIButton *)sender {
    [self enterPhotoBrowser];
}

#pragma mark - New method
- (void)enterPhotoBrowser {
    if(_mediaType) {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-video-pre"]];
    } else {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-photo-pre"]];
    }

    // Browser
    BOOL displaySelectionButtons = NO;
    
    [self addAssets];
    
    // Create browser
    ZJPhotoBrowserController *browser = [[ZJPhotoBrowserController alloc] initWithDelegate:self];
    browser.startOnGrid = YES;
    browser.backgroundColor = [UIColor whiteColor];
    
    // Reset selections
    if (displaySelectionButtons) {
        _selections = [NSMutableArray new];
        for (int i = 0; i < _photos.count; i++) {
            [_selections addObject:[NSNumber numberWithBool:NO]];
        }
    }
    
    // Modal
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    //    [self presentViewController:nc animated:YES completion:nil];
    [SHTool configureAppThemeWithController:nc];

    if ([self.delegate respondsToSelector:@selector(localAlbumCell:showLocalMediaBrowser:)]) {
        [self.delegate localAlbumCell:self showLocalMediaBrowser:nc];
    }
    
    // Test reloading of data after delay
    double delayInSeconds = 3;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    });
    
    if(_mediaType) {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-video"]];
    } else {
        [_iconBackImgView setImage:[UIImage imageNamed:@"camera roll-btn-photo"]];
    }
}

- (void)addAssets {
    NSMutableArray *photos = [[NSMutableArray alloc] init];
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    
    UIScreen *screen = [UIScreen mainScreen];
    CGFloat scale = screen.scale;
    // Sizing is very rough... more thought required in a real implementation
    CGFloat imageSize = MAX(screen.bounds.size.width, screen.bounds.size.height) * 1.5;
    CGSize imageTargetSize = CGSizeMake(imageSize * scale, imageSize * scale);
    CGSize thumbTargetSize = CGSizeMake(imageSize / 3.0 * scale, imageSize / 3.0 * scale);
    
    @synchronized (_assetsArray) {
        NSMutableArray *copy = [_assetsArray copy];
        for (PHAsset *asset in copy) {
            @autoreleasepool {
                [photos addObject:[ZJPhoto photoWithAsset:asset targetSize:imageTargetSize]];
                [thumbs addObject:[ZJPhoto photoWithAsset:asset targetSize:thumbTargetSize]];
            }
        }
    }
    
    self.photos = photos;
    self.thumbs = thumbs;
}

#pragma mark - ZJPhotoBrowserControllerDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(ZJPhotoBrowserController *)photoBrowser {
    return _photos.count;
}

- (id <ZJPhotoProtocol>)photoBrowser:(ZJPhotoBrowserController *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < _photos.count)
        return [_photos objectAtIndex:index];
    return nil;
}

- (id <ZJPhotoProtocol>)photoBrowser:(ZJPhotoBrowserController *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    if (index < _thumbs.count)
        return [_thumbs objectAtIndex:index];
    return nil;
}

- (void)photoBrowser:(ZJPhotoBrowserController *)photoBrowser deletePhotoAtIndex:(NSUInteger)index completionHandler:(nullable void (^)(BOOL))completionHandler
{
    if ([self.delegate respondsToSelector:@selector(localAlbumCell:deleteLocalAssetWithIndex:tag:completionHandler:)]) {
        [self.delegate localAlbumCell:self deleteLocalAssetWithIndex:index tag:_mediaType completionHandler:^(BOOL success) {
            if (success) {
                [self addAssets];
            }
            
            if (completionHandler) {
                completionHandler(success);
            }
        }];
    }
}

@end
