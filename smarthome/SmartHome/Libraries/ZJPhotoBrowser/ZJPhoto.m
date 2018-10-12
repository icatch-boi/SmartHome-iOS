// ZJPhoto.m

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
 
 // Created by zj on 2018/5/29 下午1:53.
    

#import "ZJPhoto.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "SDWebImageManager.h"

@interface ZJPhoto ()

@property (nonatomic, assign) BOOL loadingInProgress;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSURL *photoURL;
@property (nonatomic, strong) PHAsset *asset;
@property (nonatomic, assign) CGSize assetTargetSize;
@property (nonatomic, assign) PHImageRequestID assetRequestID;
@property (nonatomic, strong) id <SDWebImageOperation> webImageOperation;

@end

@implementation ZJPhoto

@synthesize underlyingImage = _underlyingImage;

+ (instancetype)photoWithImage:(UIImage *)image {
    return [[ZJPhoto alloc] initWithImage:image];
}

+ (instancetype)photoWithURL:(NSURL *)url {
    return [[ZJPhoto alloc] initWithURL:url];
}

+ (instancetype)photoWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    return [[ZJPhoto alloc] initWithAsset:asset targetSize:targetSize];
}

+ (instancetype)videoWithURL:(NSURL *)url {
    return [[ZJPhoto alloc] initWithVideoURL:url];
}

// MARK: - Init
- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    self = [super init];
    if (self) {
        self.image = image;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.photoURL = url;
    }
    return self;
}

- (instancetype)initWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    if ((self = [super init])) {
        self.asset = asset;
        self.assetTargetSize = targetSize;
        self.isVideo = asset.mediaType == PHAssetMediaTypeVideo;
    }
    return self;
}

- (instancetype)initWithVideoURL:(NSURL *)url {
    if ((self = [super init])) {
        self.videoURL = url;
        self.isVideo = YES;
    }
    return self;
}

// MARK: - Video
- (void)setVideoURL:(NSURL *)videoURL {
    _videoURL = videoURL;
    _isVideo = YES;
}

- (void)getVideoURL:(void (^)(NSURL *url))completion {
    if (_videoURL) {
        completion(_videoURL);
    } else if (_asset && _asset.mediaType == PHAssetMediaTypeVideo) {
        PHVideoRequestOptions *options = [PHVideoRequestOptions new];
        options.networkAccessAllowed = YES;
        [[PHImageManager defaultManager] requestAVAssetForVideo:_asset options:options resultHandler:^(AVAsset *asset, AVAudioMix *audioMix, NSDictionary *info) {
            NSLog(@"getVideoURL: %@", info);
            NSLog(@"asset: %@", asset);
            if ([asset isKindOfClass:[AVURLAsset class]]) {
                completion(((AVURLAsset *)asset).URL);
            } else if ([asset isKindOfClass:[AVComposition class]]) {
                AVComposition *comp = (AVComposition *)asset;
                NSLog(@"comp.tracks: %@", comp.tracks);
                AVCompositionTrack *track = [comp.tracks objectAtIndex:0];
                NSLog(@"track.segments: %@", track.segments);
                AVCompositionTrackSegment *seg = [track.segments objectAtIndex:0];
                NSLog(@"seg.sourceURL: %@", seg.sourceURL);
                completion(seg.sourceURL);
            } else {
                completion(nil);
            }
        }];
    } else {
        return completion(nil);
    }
}

// MARK: - ZJPhoto Protocol Methods
- (UIImage *)underlyingImage {
    return _underlyingImage;
}

- (void)loadUnderlyingImageAndNotify {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    if (_loadingInProgress) return;
    _loadingInProgress = YES;
    @try {
        if (self.underlyingImage) {
            [self imageLoadingComplete];
        } else {
            [self performLoadUnderlyingImageAndNotify];
        }
    }
    @catch (NSException *exception) {
        self.underlyingImage = nil;
        _loadingInProgress = NO;
        [self imageLoadingComplete];
    }
    @finally {
    }
}

- (void)performLoadUnderlyingImageAndNotify {
    if (_image) {
        self.underlyingImage = _image;
        [self imageLoadingComplete];
    } else if (_photoURL) {
        
        // Check what type of url it is
        if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"assets-library"]) {
            
            // Load from assets library
            [self _performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL: _photoURL];
            
        } else if ([_photoURL isFileReferenceURL]) {
            
            // Load from local file async
            [self _performLoadUnderlyingImageAndNotifyWithLocalFileURL: _photoURL];
            
        } else if ([[[_photoURL scheme] lowercaseString] isEqualToString:@"sdk"]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                @autoreleasepool {
//                    @try {
//
//                        if (_funcBlock != nil) {
//                            self.underlyingImage =  _funcBlock();
//                        }
//                        if (!_underlyingImage) {
//                            MWLog(@"Error loading photo from path: %@", _photoURL.path);
//                        }
//                    } @finally {
//                        [self performSelectorOnMainThread:@selector(imageLoadingComplete)
//                                               withObject:nil
//                                            waitUntilDone:NO];
//                    }
//                }
            });
        } else {
            // Load async from web (using SDWebImage)
            [self _performLoadUnderlyingImageAndNotifyWithWebURL: _photoURL];
        }
    } else if (_asset) {
        
        // Load from photos asset
        [self _performLoadUnderlyingImageAndNotifyWithAsset: _asset targetSize:_assetTargetSize];
        
    } else if (_videoURL) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                @try {
                    self.underlyingImage = [self getImage:self.videoURL];
                    if (!self.underlyingImage) {
                    }
                } @finally {
                    [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                }
            }
        });
    } else {
        
        // Image is empty
        [self imageLoadingComplete];
    }
}

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithWebURL:(NSURL *)url {
    @try {
        SDWebImageDownloader *downloader = [SDWebImageDownloader sharedDownloader];
        [downloader downloadImageWithURL:url
                                 options:0
                                progress:nil
                               completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                                   if (error) {
                                       NSLog(@"SDWebImage failed to download image: %@", error);
                                   }
                                   self.webImageOperation = nil;
                                   self.underlyingImage = image;
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [self imageLoadingComplete];
                                   });
                               }];
        
//        [downloader downloadImageWithURL:url
//                                 options:0
//                                progress:^(NSInteger receivedSize, NSInteger expectedSize, NSURL * _Nullable targetURL) {
//                                    if (expectedSize > 0) {
//                                        float progress = receivedSize / (float)expectedSize;
////                                        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
////                                                              [NSNumber numberWithFloat:progress], @"progress",
////                                                              self, @"photo", nil];
////                                        [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
//                                    }
//                                } completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
//                                    if (error) {
//                                        NSLog(@"SDWebImage failed to download image: %@", error);
//                                    }
//                                    self.webImageOperation = nil;
//                                    self.underlyingImage = image;
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        [self imageLoadingComplete];
//                                    });
//                                }];
    } @catch (NSException *e) {
        NSLog(@"Photo from web: %@", e);
        _webImageOperation = nil;
        [self imageLoadingComplete];
    }
}

// Load from local file
- (void)_performLoadUnderlyingImageAndNotifyWithLocalFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                self.underlyingImage = [UIImage imageWithContentsOfFile:url.path];
                if (!self.underlyingImage) {
                    NSLog(@"Error loading photo from path: %@", url.path);
                }
            } @finally {
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }
        }
    });
}

// Load from asset library async
- (void)_performLoadUnderlyingImageAndNotifyWithAssetsLibraryURL:(NSURL *)url {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            @try {
                ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
                [assetslibrary assetForURL:url
                               resultBlock:^(ALAsset *asset){
                                   ALAssetRepresentation *rep = [asset defaultRepresentation];
                                   CGImageRef iref = [rep fullScreenImage];
                                   if (iref) {
                                       self.underlyingImage = [UIImage imageWithCGImage:iref];
                                   }
                                   [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                               }
                              failureBlock:^(NSError *error) {
                                  self.underlyingImage = nil;
                                  NSLog(@"Photo from asset library error: %@",error);
                                  [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
                              }];
            } @catch (NSException *e) {
                NSLog(@"Photo from asset library error: %@", e);
                [self performSelectorOnMainThread:@selector(imageLoadingComplete) withObject:nil waitUntilDone:NO];
            }
        }
    });
}

// Load from photos library
- (void)_performLoadUnderlyingImageAndNotifyWithAsset:(PHAsset *)asset targetSize:(CGSize)targetSize {
    
    PHImageManager *imageManager = [PHImageManager defaultManager];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = false;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithDouble: progress], @"progress",
                              self, @"photo", nil];
//        [[NSNotificationCenter defaultCenter] postNotificationName:MWPHOTO_PROGRESS_NOTIFICATION object:dict];
    };
    
    _assetRequestID = [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFit options:options resultHandler:^(UIImage *result, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.underlyingImage = result;
            [self imageLoadingComplete];
        });
    }];
    
}

// Get local video thumbnail
- (UIImage *)getImage:(NSURL *)videoURL {
    
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

- (void)imageLoadingComplete {
    NSAssert([[NSThread currentThread] isMainThread], @"This method must be called on the main thread.");
    // Complete so notify
    _loadingInProgress = NO;
    // Notify on next run loop
    [self performSelector:@selector(postCompleteNotification) withObject:nil afterDelay:0];
}

- (void)postCompleteNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:kZJPhotoLoadingDidEndNotification
                                                        object:self];
}

@end
