// SHAVPlayerViewController.m

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
 
 // Created by zj on 2019/10/18 4:26 PM.
    

#import "SHAVPlayerViewController.h"
#import "SHS3FileInfo.h"
#import "SHENetworkManagerCommon.h"
#import "filecache/FileCacheManager.h"
#import "SVProgressHUD.h"
#import "AppDelegate.h"

@interface SHAVPlayerViewController () <AVPlayerViewControllerDelegate>

@property (nonatomic, strong) AVPlayerViewController *playerController;
@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) SHS3FileInfo *fileInfo;

@end

@implementation SHAVPlayerViewController

- (instancetype)initWithFileInfo:(SHS3FileInfo *)fileInfo
{
    self = [super init];
    if (self) {
        self.fileInfo = fileInfo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initParamete];
    [self loadData];
}

- (void)initParamete {
    _session = [AVAudioSession sharedInstance];
    [_session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    _player = [[AVPlayer alloc] init];
    _playerController = [[AVPlayerViewController alloc] init];
    _playerController.player = _player;
    _playerController.videoGravity = AVLayerVideoGravityResizeAspect;
    _playerController.delegate = self;
    _playerController.allowsPictureInPicturePlayback = true;    //画中画，iPad可用
    _playerController.showsPlaybackControls = true;
    
    [self addChildViewController:_playerController];
    _playerController.view.translatesAutoresizingMaskIntoConstraints = true;    //AVPlayerViewController 内部可能是用约束写的，这句可以禁用自动约束，消除报错
    _playerController.view.frame = self.view.bounds;
    [self.view addSubview:_playerController.view];
    
//    [_playerController.player play];    //自动播放
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isVideoPB = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isVideoPB = NO;
    [SHTool setupCurrentFullScreen:NO];
}

- (void)loadData {
    [SVProgressHUD showWithStatus:@"正在努力加载数据..."];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    WEAK_SELF(self);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *keyString = [NSString stringWithFormat:@"%@_%@", weakself.fileInfo.deviceID, weakself.fileInfo.fileName];
        string key = keyString.UTF8String;
        string cachePath;
        __block bool exist = FileCache::FileCacheManager::sharedFileCache()->diskFileDataExistsForKey(key, cachePath);
        
        if (exist) {
            [SVProgressHUD dismiss];

            dispatch_async(dispatch_get_main_queue(), ^{
                NSURL *url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%s", cachePath.c_str()]];
                AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url]; // create item
                [weakself.player  replaceCurrentItemWithPlayerItem:item];
                [weakself.player play];
            });
        } else {
            [[SHENetworkManager sharedManager] getFileWithDeviceID:_fileInfo.deviceID filePath:_fileInfo.filePath completion:^(BOOL isSuccess, id  _Nullable result) {
                [SVProgressHUD dismiss];
                
                if (isSuccess == YES && result != nil) {
                    AWSS3GetObjectOutput *response = result;
                    
                    if (response.body != nil) {
                        NSData *data = response.body;

                        FileCache::FileCacheManager::sharedFileCache()->storeDataForKey(key, data.bytes, (int)data.length);
                        string cachePath;
                        exist = FileCache::FileCacheManager::sharedFileCache()->diskFileDataExistsForKey(key, cachePath);
                        
                        if (exist) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSURL *url = [[NSURL alloc] initFileURLWithPath:[NSString stringWithFormat:@"%s", cachePath.c_str()]];
                                AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url]; // create item
                                [weakself.player  replaceCurrentItemWithPlayerItem:item];
                                [weakself.player play];
                            });
                        }
                    }
                } else {
                    SHLogError(SHLogTagAPP, @"Get file failed, error: %@", result);
                    [SVProgressHUD showErrorWithStatus:@"获取文件数据失败，请稍后重试"];
                    [SVProgressHUD dismissWithDelay:kPromptinfoDisplayDuration];
                }
            }];
        }
    });
}

#pragma mark - AVPlayerViewControllerDelegate
- (void)playerViewControllerWillStartPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerDidStartPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController failedToStartPictureInPictureWithError:(NSError *)error {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerWillStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (void)playerViewControllerDidStopPictureInPicture:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
}

- (BOOL)playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart:(AVPlayerViewController *)playerViewController {
    NSLog(@"%s", __FUNCTION__);
    return true;
}

- (void)playerViewController:(AVPlayerViewController *)playerViewController restoreUserInterfaceForPictureInPictureStopWithCompletionHandler:(void (^)(BOOL))completionHandler {
    NSLog(@"%s", __FUNCTION__);
}

@end
