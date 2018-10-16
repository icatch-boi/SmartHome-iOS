//
//  ViewController.m
//  SmartHome
//
//  Created by ZJ on 2017/4/11.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSinglePreviewVC.h"
#import "SHSinglePreviewVCPrivate.h"
#import "SHSDKEventListener.hpp"
#import "SHCamera.h"
#import "SHTool.h"
#import "SHMpbTVC.h"
#import "ICVoiceHud.h"
#import "RTCView.h"
#import "RTCButton.h"
#import "SHWaterView.h"
#import "CustomIOS7AlertView.h"

typedef enum : NSUInteger {
    CacheTypeVideo,
    CacheTypeAudio,
} CacheType;

static const CGFloat kMuteBtnDefaultWidth = 60;
static const CGFloat kTalkbackBtnDefaultWidth = 80;

@interface SHSinglePreviewVC () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property(nonatomic, retain) GCDiscreetNotificationView *bufferNotificationView;
@property (nonatomic) NSDate * currentDate;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) ICVoiceHud *voiceHud;
@property (nonatomic) RTCView *presentView;
@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic,getter=isConnected) BOOL connected;
@property (nonatomic) BOOL disconnectHandling;
@property (nonatomic) BOOL noHidden;
@property (nonatomic, strong) NSTimer *talkAnimTimer;
@property (nonatomic) BOOL poweroffHandling;
@property (nonatomic, weak) UINavigationController *rootViewController;

@property (nonatomic, strong) CustomIOS7AlertView *videoSizeView;
@property (nonatomic, strong) SHSettingData *videoSizeData;
@property (nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;
@property (nonatomic, strong) NSTimer *currentDateTimer;

@end

@implementation SHSinglePreviewVC

#pragma mark - Init Variable
- (void)initParameter {
    _shCameraObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = _shCameraObj.controler;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self initParameter];
    
//    if (_managedObjectContext) {
//        if (!_shCameraObj.isConnect) {
//            [self connectCamera];
//        } else {
//            _connected = YES;
//        }
//    }
    
//    [self setupSampleBufferDisplayLayer];
    [self initPreviewGUI];
    [self constructPreviewData];
    
    [self setupTalkButtonTarget];
    
    [self addGestureRecognizers];
#if 0
    if (_shCameraObj.isConnect) {
        [self prepareVideoSizeData];
    }
#endif
}

- (void)addGestureRecognizers {
    //单指单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showController)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
    
#if 0
    //双指单击
    UITapGestureRecognizer *doubleFingerOne = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                      action:@selector(handleDoubleFingerEvent:)];
    doubleFingerOne.numberOfTouchesRequired = 2;
    doubleFingerOne.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:doubleFingerOne];
    doubleFingerOne.delegate = self;
#endif
}

- (void)setupTalkButtonTarget {
    [_talkbackButton addTarget:self action:@selector(talkButtonDragInside:) forControlEvents:UIControlEventTouchDragInside];
    if(_shCameraObj.cameraProperty.talk ) {
        _TalkBackRun = _shCameraObj.cameraProperty.talk;
        [self talkAnimTimer];
    }
}

- (void)connectCamera {
    int retValue = [_shCameraObj connectCamera];
    
    if(retValue != ICH_SUCCEED) {
        NSString *name = _shCameraObj.camera.cameraName;
        NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
        NSString *errorInfo = @"";
        errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil)
                                                            message:errorInfo
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"Sure",nil)
                                                  otherButtonTitles:nil, nil];
            alert.tag = APP_CONNECT_ERROR_TAG;
            [alert show];
        });
    } else {
//        [_shCameraObj initCamera];
#if 0
        [self prepareVideoSizeData];
        [self initCameraPropertyGUI];
#endif
    }
}

//- (void)viewWillLayoutSubviews {
//    [super viewWillLayoutSubviews];
//
//    SHLogInfo(SHLogTagAPP, @"preview bounds: %@", NSStringFromCGRect(_preview.bounds));
//    SHLogInfo(SHLogTagAPP, @"self.view bounds: %@", NSStringFromCGRect(self.view.bounds));
//
//    if (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
//        self.avslayer.bounds = self.view.bounds;
//        self.avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
//
//        _footerView.hidden = YES;
//    } else {
//        self.avslayer.bounds = _preview.bounds;
//        self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
//
//        _footerView.hidden = NO;
//    }
//
//    SHLogInfo(SHLogTagAPP, @"bounds: %@, position: %@", NSStringFromCGRect(self.avslayer.bounds), NSStringFromCGPoint(self.avslayer.position));
//    SHLogInfo(SHLogTagAPP, @"================================================================");
//}

- (void)initPlayer {
    [self setupSampleBufferDisplayLayer];
    
    // FIXME: 暂时修改
    //    [self setupCallView];
    
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:^(BOOL isBuffering, BOOL timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            //            if (self.view.window) {
            //                if (timeout) {
            //                    [self.progressHUD hideProgressHUD:YES];
            //
            //                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"当前网络状况不好, preview 可能会受影响." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            //                    [alert show];
            //                } else {
            //                    if (isBuffering) {
            //                        [self.progressHUD showProgressHUDWithMessage:nil];
            //                    } else {
            //                        [self.progressHUD hideProgressHUD:YES];
            //                    }
            //                }
            //            }
            if (self.preview && isBuffering) {
                [self.bufferNotificationView showGCDNoteWithMessage:NSLocalizedString(@"PREVIEW_BUFFERING_INFO", nil) andTime:1.0 withAcvity:NO];
            }
        });
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (!_shCameraObj.isConnect) {
        [self.progressHUD showProgressHUDWithMessage:nil];
        dispatch_async(dispatch_queue_create("SimglePreviewQueue", DISPATCH_QUEUE_SERIAL), ^{
            [self connectCamera];
            
            if (_shCameraObj.isConnect) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self initPlayer];
                });
                [self startPreview];
            }
        });
    } else {
        [self initPlayer];
        
        if (!_shCameraObj.streamOper.PVRun) {
            [self startPreview];
        } else {
            [self addVideoBitRateObserver];
            [self initCameraPropertyGUI];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
    
    [self.preview addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
//    [self currentDateTimer];
    
    self.talkbackButton.enabled = _shCameraObj.cameraProperty.serverOpened;
    [self.shCameraObj.cameraProperty addObserver:self forKeyPath:@"serverOpened" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
    SHFile *file = tempDict[@"file"];
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"kFileDownloadCompleteTipsInfo", nil), tempDict[@"cameraName"], file.f.getFileName().c_str()];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.notificationView showGCDNoteWithMessage:msg andTime:kShowDownloadCompleteNoteTime withAcvity:NO];
    });
}

- (void)checkTalkBackState {
    if (_TalkBackRun) {
        _TalkBackRun = NO;
        _shCameraObj.cameraProperty.talk = NO;
        [_shCameraObj.streamOper stopTalkBack];
    }
}

- (void)cameraDisconnectHandle:(NSNotification *)nc {
    if (_disconnectHandling) {
        return;
    }
    
    _disconnectHandling = YES;
    SHCameraObject *shCamObj = nc.object;
    
    if (!shCamObj.isConnect) {
        return;
    }
    
    [self checkTalkBackState];
    
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
    
    [self showDisconnectAlert:shCamObj];
}

- (void)cameraPowerOffHandle:(NSNotification *)nc {
    if (_poweroffHandling) {
        return;
    }
    
    [self checkTalkBackState];
    
    _disconnectHandling = YES;
    _poweroffHandling = YES;
    SHCameraObject *shCamObj = nc.object;
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
    
    NSDictionary *userInfo = nc.userInfo;
    int value = [userInfo[kPowerOffEventValue] intValue];
    NSString *tipsInfo = NSLocalizedString(@"kCameraPowerOff", nil);
    if (value == 1) {
        tipsInfo = NSLocalizedString(@"kCameraPowerOffByRemoveSDCard", nil);
    }
    
    WEAK_SELF(self);
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:[NSString stringWithFormat:@"[%@] %@", shCamObj.camera.cameraName, tipsInfo] preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakself.poweroffHandling = NO;
            weakself.disconnectHandling = NO;

            [weakself goHome:nil];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self runPreview];
//    [_shCameraObj.streamOper openAudioServerWithSuccessBlock:^{
//        SHLogInfo(SHLogTagAPP, @"openAudioServer success.");
//    } failedBlock:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.progressHUD showProgressHUDNotice:@"openAudioServer failed." showTime:2.0];
//            self.talkbackButton.enabled = NO;
//        });
//    }];
    
#if 0
    if (!_shCameraObj.cameraProperty.serverOpened) {
        self.talkbackButton.enabled = NO;
    }
#endif
    
//    if (_shCameraObj.isConnect) {
//        if (_managedObjectContext) {
//            // FIXME: 暂时修改
////            NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
////            if (![msgType isEqualToString:@"201"]) {
////                [self startPreview];
////            }
//            [self startPreview];
//        } else {
//            if (!_shCameraObj.streamOper.PVRun) {
//                [self startPreview];
//            }
//        }
//    } else {
//        [self goHome:nil];
//        return;
//    }
    
//    [self addPreviewCacheObserver];
#if 0
    if (_shCameraObj.isConnect) {
        [self initCameraPropertyGUI];
    }
#endif
}

- (void)setupCallView {
    NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
    if (_managedObjectContext && [msgType isEqualToString:@"201"] && _presentView == nil) {
        _presentView = [[RTCView alloc] initWithIsVideo:NO isCallee:YES inView:self.view];
        
        [_presentView.hangupBtn addTarget:self action:@selector(hangupClick) forControlEvents:UIControlEventTouchUpInside];
        [_presentView.answerBtn addTarget:self action:@selector(answerClick) forControlEvents:UIControlEventTouchUpInside];
        
        [_presentView show];
        [self setPresentViewTitle];
        
        [self startPlayRing];
    }
}

- (void)setPresentViewTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        _presentView.portraitImageView.image = [UIImage imageNamed:@"portrait-1.jpg"];
        _presentView.nickName = _shCameraObj.camera.cameraName;
        _presentView.connectText = @"等待连接...";
        _presentView.netTipText = @"当前网络良好";
    });
}

- (void)startPlayRing
{
    NSString *ringPath = [[NSBundle mainBundle] pathForResource:@"test.caf" ofType:nil];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;  // 加上这两句，否则声音会很小
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
    
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ringPath] error:nil];
    self.player.numberOfLoops = -1;
    [self.player prepareToPlay];
    [self.player play];
}

- (void)stopPlayRing
{
    [self.player stop];
    self.player = nil;
}

- (void)hangupClick {
    [self stopPlayRing];
    
    if (_shCameraObj.isConnect && !self.isConnected) {
        [self.progressHUD showProgressHUDWithMessage:nil];
        [_shCameraObj disConnectWithSuccessBlock:^{
            [self goHome:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
            });
        } failedBlock:^{
            [self goHome:nil];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
            });
        }];
    } else {
        [self goHome:nil];
    }
}

- (void)answerClick {
    [self stopPlayRing];

    if (_shCameraObj.isConnect) {
        [self startPreview];
    }
    
    [UIView animateWithDuration:0.5 animations:^{
        self.presentView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.presentView removeFromSuperview];
    }];
}

- (void)startPreview {
//    [self.progressHUD showProgressHUDWithMessage:nil];
    [_shCameraObj.streamOper startMediaStreamWithEnableAudio:YES file:nil successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self initCameraPropertyGUI];
            
            [self enableUserInteraction:YES];
        });
#if 0
        NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
        if ([msgType isEqualToString:@"201"]) {
            if (_shCameraObj.controler.actCtrl.isRecord == NO) {
                [self startVideoRec];
            }
        }
#endif
        [_shCameraObj initCamera];
        [self addVideoBitRateObserver];
    } failedBlock:^(NSInteger errorCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *notice = NSLocalizedString(@"StartPVFailed", nil);
            if (errorCode == ICH_PREVIEWING_BY_OTHERS) {
                notice = @"Previewing by others";
            } else if (errorCode == ICH_PLAYING_VIDEO_BY_OTHERS) {
                notice = @"Playing video by others";
            }
            [self.progressHUD showProgressHUDNotice:notice showTime:2.0];
            [self enableUserInteraction:NO];
        });
        
//        [_shCameraObj initCamera];
    } target:nil streamCloseCallback:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
//    if (_TalkBackRun) {
//        [self talkBackAction:nil];
//    }
    [self releaseTalkAnimTimer];
    
    if (_managedObjectContext) {
        if (_shCameraObj.streamOper.PVRun) {
            [_shCameraObj.streamOper stopMediaStreamWithComplete:nil];
        }
    }
    
    [super viewWillDisappear:animated];
    
    //    [_shCameraObj.streamOper closeAudioServer];
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:nil];
    [self.avslayer removeFromSuperlayer];
    
    _notification = nil;
    
    if (_rootViewController) {
        [self restoreRootViewController:_rootViewController];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.preview  removeObserver:self forKeyPath:@"bounds"];
    
    [self removePreviewCacheObserver];
    [self releaseCurrentDateTimer];
    [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    SHLogDebug(SHLogTagAPP, @"%@ - dealloc", self.class);
    
    [self deconstructPreviewData];
}

- (IBAction)goHome:(id)sender {
//    _TalkBackRun = NO;
//    [self.progressHUD showProgressHUDWithMessage:nil];
//    SHLogInfo(SHLogTagAPP, @"stopTalkBack");
//
//    [_shCameraObj.streamOper stopTalkBackWithSuccessBlock:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            SHLogInfo(SHLogTagAPP, @"success to stop talkBack");
//            _shCameraObj.cameraProperty.previewMode &= ~SHPreviewModeTalkBackOnFlag;
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
//            [self.progressHUD hideProgressHUD:YES];
//        });
//        //[_shCameraObj.streamOper closeAudioServer];
//    } failedBlock:^{
//        dispatch_async(dispatch_get_main_queue(), ^{
//            SHLogInfo(SHLogTagAPP, @"Failed to stop talkBack");
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
//            [self.progressHUD showProgressHUDNotice:@"Failed to stop talkBack." showTime:2.0];
//        });
//        //[_shCameraObj.streamOper closeAudioServer];
//    }];

//	[_shCameraObj.streamOper closeAudioServer];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (_presentView) {
            [_presentView removeFromSuperview];
            _presentView = nil;
        }
    });
        
    if (_managedObjectContext) {
        [self.progressHUD showProgressHUDWithMessage:nil];
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
            if ([msgType isEqualToString:@"201"]) {
                if (_shCameraObj.controler.actCtrl.isRecord) {
                    [self stopVideoRec];
                }
            }
            
            if (self.isForeground) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
                    
                    [self dismissViewControllerAnimated:YES completion:^{
                        SHLogInfo(SHLogTagAPP, @"QUIT -- FullScreen");
                    }];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
                    
                    [self performSegueWithIdentifier:@"go2HomeSegue" sender:nil];
                });
            }
//        });
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            SHLogInfo(SHLogTagAPP, @"QUIT -- FullScreen");
        }];
    }
}

#pragma mark - Init Preview GUI
- (void)setupSampleBufferDisplayLayer {
//    self.avslayer = [[AVSampleBufferDisplayLayer alloc] init];
//    self.avslayer.bounds = _preview.bounds;
//    self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
//    self.avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    self.avslayer.backgroundColor = [[UIColor blackColor] CGColor];
//
//    CMTimebaseRef controlTimebase;
//    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
//    self.avslayer.controlTimebase = controlTimebase;
//    //    CMTimebaseSetTime(self.avslayer.controlTimebase, CMTimeMake(5, 1));
//    CMTimebaseSetRate(self.avslayer.controlTimebase, 1.0);
//
//    [self.preview.layer addSublayer:self.avslayer];
    
    AVSampleBufferDisplayLayer *avslayer = _shCameraObj.cameraProperty.avslayer;
    if (avslayer == nil) {
        avslayer = [[AVSampleBufferDisplayLayer alloc] init];
    }

    avslayer.bounds = _preview.bounds;
    avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
    avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avslayer.backgroundColor = [[UIColor blackColor] CGColor];

    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    avslayer.controlTimebase = controlTimebase;

    CMTimebaseSetRate(avslayer.controlTimebase, 1.0);

    self.avslayer = avslayer;
    
    [self.preview.layer addSublayer:self.avslayer];
}

- (void)initPreviewGUI {
    NSString *mode = [_shCameraObj.sdk getTutkConnectMode];
    NSString *temp = mode ? [NSString stringWithFormat:@"%@ : %@", _shCameraObj.camera.cameraName, mode] : [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"kCameraName", @""), _shCameraObj.camera.cameraName];
    _cameraNameLabel.text = temp;
	self.curTimeLabel.hidden = YES;
    
//    [self setButtonRadius:self.talkbackButton withRadius:kButtonRadius];
//    [self setButtonRadius:self.muteButton withRadius:kButtonRadius];
//    [self setButtonRadius:self.captureButton withRadius:kButtonRadius];
//    [self setButtonRadius:self.recordButton withRadius:kButtonRadius ];
//    [_talkbackButton setCornerWithRadius:_talkbackButton.bounds.size.width * 0.5];
//    [_muteButton setCornerWithRadius:kButtonRadius];
//    [_captureButton setCornerWithRadius:_captureButton.bounds.size.width * 0.5];
//    [_recordButton setCornerWithRadius:_recordButton.bounds.size.width * 0.5];
    
//    self.talkbackButton.backgroundColor = [UIColor lightGrayColor];
//    self.captureButton.backgroundColor = [UIColor lightGrayColor];
//    self.recordButton.backgroundColor = [UIColor lightGrayColor];

    [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
    
//    _headerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
//    _footerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    _headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    _footerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    [_footerView setCornerWithRadius:5.0];
    
    _muteBtnWidthCons.constant = kMuteBtnDefaultWidth * kScreenWidthScale;
    _talkbackBtnWidthCons.constant = kTalkbackBtnDefaultWidth * kScreenWidthScale;
    _captureBtnWidthCons.constant = kMuteBtnDefaultWidth * kScreenWidthScale;
    
    UIImage *img = _shCameraObj.camera.thumbnail;
//    img = img ? img : [UIImage imageNamed:@"default_thumb"];
    _preview.image = [img ic_imageWithSize:_preview.bounds.size backColor:self.view.backgroundColor];
    _bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", 100 + (arc4random() % 100)];
}

- (void)setButtonRadius:(UIButton *)button withRadius:(CGFloat)radius {
    button.layer.cornerRadius = radius;
    button.layer.masksToBounds = YES;
}

- (void)constructPreviewData {
    NSString *stillCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"Capture_Shutter" ofType:@"WAV"];
    id url = [NSURL fileURLWithPath:stillCaptureSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_stillCaptureSound);
    
    NSString *delayCaptureBeepUri = [[NSBundle mainBundle] pathForResource:@"DelayCapture_BEEP" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:delayCaptureBeepUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_delayCaptureSound);
    
    NSString *changeModeSoundUri = [[NSBundle mainBundle] pathForResource:@"ChangeMode" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:changeModeSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_changeModeSound);
    
    NSString *videoCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"StartStopVideoRec" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:videoCaptureSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_videoCaptureSound);
    
    NSString *burstCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"BurstCapture&TimelapseCapture" ofType:@"WAV"];
    url = [NSURL fileURLWithPath:burstCaptureSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_burstCaptureSound);
}

- (void)deconstructPreviewData {
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
    AudioServicesDisposeSystemSoundID(_delayCaptureSound);
    AudioServicesDisposeSystemSoundID(_changeModeSound);
    AudioServicesDisposeSystemSoundID(_videoCaptureSound);
    AudioServicesDisposeSystemSoundID(_burstCaptureSound);
}

- (void)voiceDidStartRecording
{
    [self timerInvalue];
    self.voiceHud.hidden = NO;
    [self timer];
}

- (void)voiceDidCancelRecording
{
    [self timerInvalue];
    self.voiceHud.hidden = YES;
}

- (void)setNeedsUpdateTalkIcon:(BOOL)need {
    [self voiceWillDragout:need];

    if (need) {
//        self.talkbackButton.backgroundColor = [UIColor redColor];
//        [_muteButton setImage:[UIImage imageNamed:@"icon_voiceClose"]
//                               forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];
    } else {
//        self.talkbackButton.backgroundColor = [UIColor lightGrayColor];
//        [_muteButton setImage:[UIImage imageNamed:@"icon_voice"]
//                               forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute_1"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
    }
}

#pragma mark - Preview
- (void)checkAudioStatus:(void (^)(void))handler failedHandler:(void (^)(void))failedHander {
    // 1、 获取麦克风设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    if (device) {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
        if (status == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if (granted) {
                    // 用户第一次同意了访问麦克风权限
                    handler();
                } else {
                    // 用户第一次拒绝了访问麦克风权限
                    failedHander();
                }
            }];
        } else if (status == AVAuthorizationStatusAuthorized) { // 用户允许当前应用访问麦克风
            handler();
        } else if (status == AVAuthorizationStatusDenied) { // 用户拒绝当前应用访问麦克风
            UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning", @"") message:NSLocalizedString(@"kMicrophoneAccessWarningInfo", @"") preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                failedHander();
            }];
            
            [alertC addAction:alertA];
            [self presentViewController:alertC animated:YES completion:nil];
        } else if (status == AVAuthorizationStatusRestricted) {
            NSLog(@"因为系统原因, 无法访问麦克风");
            failedHander();
        }
    } else {
        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", @"") message:NSLocalizedString(@"kMicrophoneNotDetected", @"") preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *alertA = [UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", @"") style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            failedHander();
        }];
        
        [alertC addAction:alertA];
        [self presentViewController:alertC animated:YES completion:nil];
    }
}

- (void)talkButtonDragInside:(UIButton *)sender {
    [self setNeedsUpdateTalkIcon:YES];
}

- (IBAction)talkBackTouchDown:(UIButton *)sender {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        _currentDate = [NSDate date];

        [self checkAudioStatus:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (sender.state != UIControlStateHighlighted) {
                    SHLogError(SHLogTagAPP, @"talkbackButton unlock.");
                } else {
                    self.talkbackButton.enabled = YES;
                    
                    if (!_TalkBackRun) {
                        SHLogTRACE();
                        _TalkBackRun = YES;

                        [self startTalkBack];
                        _talkbackButton.enabled = NO;
                        _noHidden = YES;
                    } else {
                        SHLogTRACE();
//                        self.talkbackButton.backgroundColor = [UIColor redColor];
                        [self setMuteButtonBackgroundImage];
                    }
                    
                    [self voiceDidStartRecording];
                    [self setNeedsUpdateTalkIcon:YES];
                }
            });
        } failedHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.talkbackButton.enabled = NO;
            });
        }];
    }
}

- (IBAction)talkBackAction:(UIButton *)sender {
    SHLogTRACE();
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        NSDate *endDate = [NSDate date];
        NSTimeInterval interval = [endDate timeIntervalSinceDate:_currentDate];
        SHLogInfo(SHLogTagAPP, @"interval : %f", interval);
        
        if (_TalkBackRun /*&& interval > 1.0*/) {
            _TalkBackRun = NO;

            [self stopTalkBack];
            _noHidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
//                self.talkbackButton.backgroundColor = [UIColor lightGrayColor];
                [self setMuteButtonBackgroundImage];
            });
        }
        
        [self voiceDidCancelRecording];
        [self setNeedsUpdateTalkIcon:NO];
    } else {
        [self checkAudioStatus:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.talkbackButton.enabled = YES;
            });

            if (!_TalkBackRun) {
                _TalkBackRun = YES;

                [self startTalkBack];
            } else {
                _TalkBackRun = NO;

                [self stopTalkBack];
//                [self voiceDidCancelRecording];
                [self releaseTalkAnimTimer];
            }
        } failedHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.talkbackButton.enabled = NO;
            });
        }];
    }
}

- (void)startTalkBack {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        [self.progressHUD showProgressHUDWithMessage:nil];
    }
    SHLogInfo(SHLogTagAPP, @"startTalkBack");

    [_shCameraObj.streamOper startTalkBackWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			_shCameraObj.cameraProperty.previewMode |= SHPreviewModeTalkBackOnFlag;
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
                [self.progressHUD hideProgressHUD:YES];
//                [self voiceDidStartRecording];
                [self talkAnimTimer];
            }
            
            _shCameraObj.cameraProperty.talk = YES;
            _noHidden = YES;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStartTalkBackFailed", @"") showTime:2.0];
			[self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            
//            [self voiceDidCancelRecording];
            [self releaseTalkAnimTimer];
            
            _shCameraObj.cameraProperty.talk = NO;
        });
    }];
}

- (void)stopTalkBack {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        [self.progressHUD showProgressHUDWithMessage:nil];
    }
    SHLogInfo(SHLogTagAPP, @"stopTalkBack");
    
    _shCameraObj.cameraProperty.talk = NO;
    [_shCameraObj.streamOper stopTalkBackWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			SHLogInfo(SHLogTagAPP, @"success to stop talkBack");
			_shCameraObj.cameraProperty.previewMode &= ~SHPreviewModeTalkBackOnFlag;
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self.progressHUD hideProgressHUD:YES];
            
            _talkbackButton.enabled = YES;
            _noHidden = NO;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			SHLogInfo(SHLogTagAPP, @"Failed to stop talkBack");
			[self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStopTalkBackFailed", @"") showTime:2.0];
            
            _talkbackButton.enabled = YES;
        });
    }];
}

- (IBAction)muteAction:(UIButton *)sender {
    SHLogTRACE();
    
//    [self.progressHUD showProgressHUDWithMessage:nil];
    [_shCameraObj.streamOper isMute:sender.tag successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sender.tag == 0) {
                sender.tag = 1;
//                [sender setImage:[UIImage imageNamed:@"icon_voiceClose"]
//                                  forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];

            } else {
                sender.tag = 0;
//                [sender setImage:[UIImage imageNamed:@"icon_voice"]
//                                  forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute_1"] forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
            }
            
//            [self.progressHUD hideProgressHUD:YES];
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kAudioControl", @"") showTime:2.0];
        });
    }];
}

- (IBAction)captureAction:(id)sender {
    SHLogTRACE();
    
    AudioServicesPlaySystemSound(_stillCaptureSound);
    [self.progressHUD showProgressHUDWithMessage:nil];
    
#if 0
    [_shCameraObj.controler.actCtrl stillCaptureWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
#if 0
            [self.progressHUD hideProgressHUD:YES];
#else
            [self.progressHUD showProgressHUDNotice:@"Capture success" showTime:1.0];
#endif
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_CAPTURE_FAILED", nil) showTime:2.0];
        });
    }];
#else
    [_shCameraObj.streamOper stillCaptureWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:@"Capture success" showTime:1.0];
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_CAPTURE_FAILED", nil) showTime:1.5];
        });
    }];
#endif
}

- (IBAction)recordAction:(id)sender {
    SHLogTRACE();
	if((_shCameraObj.cameraProperty.previewMode & SHPreviewModeVideoOnFlag) == 0){
		[self startVideoRec];
	}else if((_shCameraObj.cameraProperty.previewMode & SHPreviewModeVideoOnFlag) == SHPreviewModeVideoOnFlag){
		[self stopVideoRec];
	}
//    switch (_shCameraObj.cameraProperty.previewMode) {
//        case SHPreviewModeVideoOff:
//            [self startVideoRec];
//            break;
//            
//        case SHPreviewModeVideoOn:
//            [self stopVideoRec];
//            break;
//            
//        default:
//            break;
//    }
}

- (void)startVideoRec {
    AudioServicesPlaySystemSound(_videoCaptureSound);
    [self.progressHUD showProgressHUDWithMessage:nil];
    SHLogInfo(SHLogTagAPP, @"startVideoRec");
    
    __weak typeof(self) weakSelf = self;
    [_shCameraObj.controler.actCtrl setVideoRecordingTimerBlock:^{
        [weakSelf videoRecordingTimerCallback_SinglePV];
    }];
    [_shCameraObj.controler.actCtrl setUpdateVideoRecordTimerLabel:^ (NSDictionary *change){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSUInteger sec = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
            weakSelf.videoRecordTimerLabel.text = [NSString translateSecsToString:sec];
        });
    }];
    
    [_shCameraObj.controler.actCtrl startVideoRecWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			_shCameraObj.cameraProperty.previewMode |= SHPreviewModeVideoOnFlag;
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self setVideoRecordBlock];
            [self.progressHUD hideProgressHUD:YES];
            
            _noHidden = YES;
        });
    } failedBlock:^(int result) {
        NSString *notice = NSLocalizedString(@"kStartVideoRecordFailed", @"");
        
        switch (result) {
            case ICH_SD_CARD_NOT_EXIST:
                notice = NSLocalizedString(@"NoCard", nil);
                break;
                
            case ICH_SD_CARD_MEMORY_FULL:
                notice = NSLocalizedString(@"CARD_FULL", nil);
                break;
                
            case ICH_PIR_RECORDING:
                notice = NSLocalizedString(@"kPirRecording", nil);
                break;
                
            case ICH_APP_RECORDING:
                notice = NSLocalizedString(@"kAPPRecording", nil);
                break;
                
            default:
                break;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:notice showTime:2.0];
//            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStartVideoRecordFailed", @"") showTime:2.0];
        });
    } noCardBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"NoCard", nil) showTime:2.0];
        });
    } cardFullBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil) showTime:2.0];
        });
    }];
}

- (void)stopVideoRec
{
    AudioServicesPlaySystemSound(_videoCaptureSound);
    [self.progressHUD showProgressHUDWithMessage:nil];
    SHLogInfo(SHLogTagAPP, @"stopVideoRec");
    
    [_shCameraObj.controler.actCtrl stopVideoRecWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
			_shCameraObj.cameraProperty.previewMode &= ~SHPreviewModeVideoOnFlag;
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self.progressHUD hideProgressHUD:YES];
            
            _noHidden = NO;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStopVideoRecordFailed", @"")
                                               showTime:2.0];
        });
    }];
}

- (void)videoRecordingTimerCallback_SinglePV {
//     NSString* date;
//     
//     NSDateFormatter * formatter = [[NSDateFormatter alloc ] init];
//     //[formatter setDateFormat:@"YYYY.MM.dd.hh.mm.ss"];
//     [formatter setDateFormat:@"HH:mm:ss"];
//     date = [formatter stringFromDate:[NSDate date]];
//     NSString *timeNow = [[NSString alloc] initWithFormat:@"%@", date];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        self.curTimeLabel.text = timeNow;
//    });
    UIImage *image = nil;
    
    if (_videoReCordStartOn) {
        self.videoReCordStartOn = NO;
        image = self.startOnImage;
    } else {
        self.videoReCordStartOn = YES;
        image = self.startOffImage;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.recordButton setImage:image forState:UIControlStateNormal];
    });
}

- (IBAction)settingAction:(id)sender {
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_shCameraObj.streamOper initAVSLayer:nil bufferingBlock:nil];
        [_shCameraObj.streamOper stopMediaStreamWithComplete:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self performSegueWithIdentifier:@"go2SettingSegue" sender:nil];
        });
    });
}

- (IBAction)mpbAction:(id)sender {
    [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_shCameraObj.streamOper initAVSLayer:nil bufferingBlock:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self performSegueWithIdentifier:@"go2MpbSegue" sender:nil];
        });
    });
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navController = segue.destinationViewController;
    
    if ([segue.identifier isEqualToString:@"go2SettingSegue"]) {
#if 0
        SHSettingTVC *vc = (SHSettingTVC *)navController.topViewController;
        vc.cameraUid = _cameraUid;
#endif
    } else if ([segue.identifier isEqualToString:@"go2MpbSegue"]) {
        SHMpbTVC *vc = (SHMpbTVC *)navController.topViewController;
        vc.cameraUid = _cameraUid;
    } else if ([segue.identifier isEqualToString:@"go2HomeSegue"]) {
        // FIXME: need modify
#if 0
        SHCameraListTVC *vc = (SHCameraListTVC *)navController.topViewController;
        vc.managedObjectContext = self.managedObjectContext;
        vc.hasGuide = YES;
        _rootViewController = navController;
#endif
    }
}

- (void)restoreRootViewController:(UIViewController *)rootViewController
{
    typedef void (^Animation)(void);
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    
    rootViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    Animation animation = ^{
        BOOL oldState = [UIView areAnimationsEnabled];
        [UIView setAnimationsEnabled:NO];
        window.rootViewController = rootViewController;
        [window makeKeyAndVisible];
        [UIView setAnimationsEnabled:oldState];
    };
    
    [UIView transitionWithView:window
                      duration:0.5f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:animation
                    completion:nil];
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        UIView *v = self.view.window;
        if (v == nil) {
            v = self.view;
        }
        
        _progressHUD = [MBProgressHUD progressHUDWithView:v];
    }
    
    return _progressHUD;
}

#pragma mark - Update Preview GUI
- (void)updatePreviewSceneByMode:(SHPreviewMode)mode
{
    _shCameraObj.cameraProperty.previewMode |= mode;
    SHLogInfo(SHLogTagAPP, @"camera.previewMode: %lu", (unsigned long)_shCameraObj.cameraProperty.previewMode);
	if((mode & SHPreviewModeVideoOnFlag) == SHPreviewModeVideoOnFlag){
		[self setToVideoOnScene];
	}else if((mode & SHPreviewModeVideoOnFlag) == 0){
		[self setToVideoOffScene];
	}
	
	if((mode & SHPreviewModeTalkBackOnFlag) == SHPreviewModeTalkBackOnFlag){
		[self setToTalkBackOnScene];
	}else if((mode & SHPreviewModeTalkBackOnFlag) == 0){
		[self setToTalkBackOffScene];
	}
	
	
//    switch (mode) {
//        case SHPreviewModeCameraOff:
////            [self setToCameraOffScene];
//            break;
//        case SHPreviewModeCameraOn:
//            //[self setToCameraOnScene];
//            break;
//        case SHPreviewModeVideoOff:
//            [self setToVideoOffScene];
//            break;
//        case SHPreviewModeVideoOn:
//            [self setToVideoOnScene];
//            break;
//        case SHPreviewModeTalkBackOff:
//            [self setToTalkBackOffScene];
//            break;
//        case SHPreviewModeTalkBackOn:
//            [self setToTalkBackOffScene];
//            break;
//        default:
//            break;
//    }
}

- (void)setMuteButtonBackgroundImage {
    _muteButton.tag = _shCameraObj.cameraProperty.isMute;
    if (_muteButton.tag) {
//        [_muteButton setImage:[UIImage imageNamed:@"icon_voiceClose"]
//                               forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];
    } else {
//        [_muteButton setImage:[UIImage imageNamed:@"icon_voice"]
//                               forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute_1"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
    }
}

- (void)setToVideoOffScene {
    [self.talkbackButton setEnabled:YES];
    [self.captureButton setEnabled:YES];
    [self.muteButton setEnabled:YES];
    [self.recordButton setEnabled:YES];
    
//    self.curTimeLabel.hidden = YES;
    self.videoRecordTimerLabel.hidden = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.recordButton setImage:[UIImage imageNamed:@"ic_video_camera_white_36dp"] forState:UIControlStateNormal];
        self.recordButton.backgroundColor = [UIColor lightGrayColor];
//        self.talkbackButton.backgroundColor = [UIColor lightGrayColor];
    });
    
    [self setMuteButtonBackgroundImage];
    
    if (_shCameraObj.controler.actCtrl.isRecord) {
        __weak typeof(self) weakSelf = self;
        [_shCameraObj.controler.actCtrl setVideoRecordingTimerBlock:^{
            [weakSelf videoRecordingTimerCallback_SinglePV];
        }];
        [_shCameraObj.controler.actCtrl setUpdateVideoRecordTimerLabel:^ (NSDictionary *change){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger sec = [[change objectForKey:NSKeyValueChangeNewKey] unsignedIntegerValue];
                weakSelf.videoRecordTimerLabel.text = [NSString translateSecsToString:sec];
            });
        }];
        [self setVideoRecordBlock];
        
//        if (self.curTimeLabel.isHidden) {
//            self.curTimeLabel.hidden = NO;
//        }
		
        if (self.videoRecordTimerLabel.isHidden) {
            self.videoRecordTimerLabel.hidden = NO;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.recordButton.backgroundColor = [UIColor redColor];
        });
    }
}

- (void)setToVideoOnScene
{
    [self setToVideoOffScene];
    
//    if (self.talkbackButton.isEnabled) {
//        self.talkbackButton.enabled = NO;
//    }
//    
//    if (self.captureButton.isEnabled) {
//        self.captureButton.enabled = NO;
//    }
    
//    if (self.curTimeLabel.isHidden) {
//        self.curTimeLabel.hidden = NO;
//    }
	
    if (self.videoRecordTimerLabel.isHidden) {
        self.videoRecordTimerLabel.hidden = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.recordButton setImage:[UIImage imageNamed:@"ic_video_camera_white_36dp"] forState:UIControlStateNormal];
        self.recordButton.backgroundColor = [UIColor lightGrayColor];
    });
}

- (void)setToTalkBackOffScene {
    
}

- (void)setToTalkBackOnScene {
//    if (self.recordButton.isEnabled) {
//        self.recordButton.enabled = NO;
//    }
//    
//    if (self.captureButton.isEnabled) {
//        self.captureButton.enabled = NO;
//    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
            if (_shCameraObj.cameraProperty.isMute) {
//                self.talkbackButton.backgroundColor = [UIColor redColor];
            } else {
//                self.talkbackButton.backgroundColor = [UIColor lightGrayColor];
            }
        } else {
//            self.talkbackButton.backgroundColor = [UIColor redColor];
        }
    });
}

#pragma mark - Observer
- (void)setVideoRecordBlock {
    __weak typeof(self) weakSelf = self;
    
    [_shCameraObj.controler.actCtrl setVideoRecordBlock:^ (SHICatchEvent *evt){
        switch (evt.eventID) {
            case ICATCH_EVENT_VIDEO_OFF:
                [weakSelf updateVideoRecState];
                break;
                
            case ICATCH_EVENT_SDCARD_FULL:
                [weakSelf sdCardFull];
                break;
                
            default:
                break;
        }
    }];
}

- (void)updateVideoRecState {
    SHLogTRACE();
}

- (void)sdCardFull {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"CARD_FULL", nil)
                                           showTime:1.5];
        
    });
}

#pragma mark - GCDiscreetNotificationView
- (GCDiscreetNotificationView *)notificationView {
    if (!_notificationView) {
        _notificationView = [[GCDiscreetNotificationView alloc] initWithText:nil
                                                                showActivity:NO
                                                          inPresentationMode:GCDiscreetNotificationViewPresentationModeTop
                                                                      inView:self.view];
    }
    return _notificationView;
}

- (GCDiscreetNotificationView *)bufferNotificationView {
    if (_bufferNotificationView == nil) {
        _bufferNotificationView = [[GCDiscreetNotificationView alloc] initWithText:nil showActivity:NO inPresentationMode:GCDiscreetNotificationViewPresentationModeTop inView:self.preview];
    }
    
    return _bufferNotificationView;
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case APP_CONNECT_ERROR_TAG:
            [self stopPlayRing];
            [self goHome:nil];
            break;
            
        default:
            break;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            
            if (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
                self.avslayer.bounds = self.view.bounds;
                self.avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
                
//                _footerView.hidden = YES;
            } else {
                self.avslayer.bounds = _preview.bounds;
                self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
                
//                _footerView.hidden = NO;
            }
            
            [CATransaction commit];
        });
    } else if ([keyPath isEqualToString:@"serverOpened"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.talkbackButton.enabled = _shCameraObj.cameraProperty.serverOpened;
        });
    }
}

- (ICVoiceHud *)voiceHud {
    if (_voiceHud == nil) {
        _voiceHud = [[ICVoiceHud alloc] initWithFrame:CGRectMake(0, 0, 155, 155)];
        _voiceHud.hidden = YES;
        [self.view addSubview:_voiceHud];
        _voiceHud.center = CGPointMake([[UIScreen mainScreen] bounds].size.width * 0.5, [[UIScreen mainScreen] bounds].size.height * 0.5 - 20);
    }
    
    return _voiceHud;
}

// 向外或向里移动
- (void)voiceWillDragout:(BOOL)inside
{
    if (inside) {
        [_timer setFireDate:[NSDate distantPast]];
        _voiceHud.image  = [UIImage imageNamed:@"voice_1"];
    } else {
        [_timer setFireDate:[NSDate distantFuture]];
        self.voiceHud.animationImages  = nil;
        self.voiceHud.image = [UIImage imageNamed:@"cancelVoice"];
    }
}

- (void)progressChange
{
//    AVAudioRecorder *recorder = [[AVAudioRecorder alloc] init] ;
//    [recorder updateMeters];
//    float power= [recorder averagePowerForChannel:0];//取得第一个通道的音频，注意音频强度范围时-160到0,声音越大power绝对值越小
//    CGFloat progress = (1.0/160)*(power + 160);
    self.voiceHud.progress = 0.8;//progress;
}

- (void)timerInvalue
{
    [_timer invalidate];
    _timer  = nil;
}

- (NSTimer *)timer
{
    if (!_timer) {
        _timer =[NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(progressChange) userInfo:nil repeats:YES];
    }
    return _timer;
}

#pragma mark - Preview Cache Observer
- (void)addPreviewCacheObserver {
    SHSDKEventListener *videoCacheListener = new SHSDKEventListener(self, @selector(updatePreviewCacheInfo:));
    self.videoCacheObserver = [SHObserver cameraObserverWithListener:videoCacheListener eventType:ICATCH_EVENT_PREVIEW_VIDEO_CACHE_STATUS isCustomized:NO isGlobal:NO];
    [_shCameraObj.sdk addObserver:self.videoCacheObserver];
    
    SHSDKEventListener *audioCacheListener = new SHSDKEventListener(self, @selector(updatePreviewCacheInfo:));
    self.audioCacheObserver = [SHObserver cameraObserverWithListener:audioCacheListener eventType:ICATCH_EVENT_PREVIEW_AUDIO_CACHE_STATUS isCustomized:NO isGlobal:NO];
    [_shCameraObj.sdk addObserver:self.audioCacheObserver];
}

- (void)removePreviewCacheObserver {
    if (self.videoCacheObserver) {
        [_shCameraObj.sdk removeObserver:self.videoCacheObserver];
        
        if (self.videoCacheObserver.listener) {
            delete self.videoCacheObserver.listener;
            self.videoCacheObserver.listener = NULL;
        }
        
        self.videoCacheObserver = nil;
    }
    
    if (self.audioCacheObserver) {
        [_shCameraObj.sdk removeObserver:self.audioCacheObserver];
        
        if (self.audioCacheObserver.listener) {
            delete self.audioCacheObserver.listener;
            self.audioCacheObserver.listener = NULL;
        }
        
        self.audioCacheObserver = nil;
    }
}

- (void)updatePreviewCacheInfo:(SHICatchEvent *)evt {
    switch (evt.eventID) {
        case ICATCH_EVENT_PREVIEW_VIDEO_CACHE_STATUS:
            [self createCacheInfo:evt type:CacheTypeVideo];
            break;
            
        case ICATCH_EVENT_PREVIEW_AUDIO_CACHE_STATUS:
            [self createCacheInfo:evt type:CacheTypeAudio];
            break;
            
        default:
            break;
    }
}

- (void)createCacheInfo:(SHICatchEvent *)evt type:(CacheType)type {
    NSString *info = [NSString stringWithFormat:@" count: %02d time: %.3f cachePts: %.3f", evt.intValue1, evt.doubleValue1, evt.doubleValue2];
    BOOL isCaching = evt.intValue2 ? YES : NO;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (type == CacheTypeVideo) {
            _videoCacheLabel.text = [@"Video cache" stringByAppendingString:info];
            if (isCaching) {
                _videoCacheLabel.textColor = [UIColor redColor];
            } else {
                _videoCacheLabel.textColor = [UIColor whiteColor];
            }
        } else {
            _audioCacheLabel.text = [@"Audio cache" stringByAppendingString:info];
            if (isCaching) {
                _audioCacheLabel.textColor = [UIColor redColor];
            } else {
                _audioCacheLabel.textColor = [UIColor whiteColor];
            }
        }
    });
}

#pragma mark - Disconnect & Reconnect
- (void)showDisconnectAlert:(SHCameraObject *)shCamObj {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"kDisconnect", @"")] message:NSLocalizedString(@"kDisconnectTipsInfo", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Exit", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _disconnectHandling = NO;
            
            if ([self.delegate respondsToSelector:@selector(disconnectHandle)]) {
                [self.delegate disconnectHandle];
            }
//            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [self goHome:nil];
        });
    }]];
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"STREAM_RECONNECT", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf reconnect:shCamObj];
    }]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

- (void)reconnect:(SHCameraObject *)shCamObj {
    [self.progressHUD showProgressHUDWithMessage:[NSString stringWithFormat:@"%@ %@...", shCamObj.camera.cameraName, NSLocalizedString(@"kReconnecting", @"")]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        int retValue = [shCamObj connectCamera];
        if (retValue == ICH_SUCCEED) {
            [shCamObj initCamera];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                
                [self viewWillAppear:YES];
                [self viewDidAppear:YES];
                
                _disconnectHandling = NO;
            });
        } else {
            NSString *name = shCamObj.camera.cameraName;
            NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
            NSString *errorInfo = @"";
            errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
            
            [self showConnectErrorAlert:errorInfo cameraObj:shCamObj];
        }
    });
}

- (void)showConnectErrorAlert:(NSString *)errorInfo cameraObj:(SHCameraObject *)shCamObj {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"ConnectError", nil)] message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _disconnectHandling = NO;
            
//            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [self goHome:nil];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
        [self presentViewController:alertVc animated:YES completion:nil];
    });
}

- (void)showController {
    if (_noHidden) {
        self.headerView.hidden = NO;
        self.talkbackButton.hidden = NO;
        self.captureButton.hidden = NO;
        self.recordButton.hidden = NO;
        _footerView.hidden = NO;
        _muteButton.hidden = NO;
    } else {
        if (self.headerView.isHidden) {
            self.headerView.hidden = NO;
            self.talkbackButton.hidden = NO;
            self.captureButton.hidden = NO;
            self.recordButton.hidden = NO;
            _footerView.hidden = NO;
            _muteButton.hidden = NO;
        } else {
            self.headerView.hidden = YES;
            self.talkbackButton.hidden = YES;
            self.captureButton.hidden = YES;
            self.recordButton.hidden = YES;
            _footerView.hidden = YES;
            _muteButton.hidden = YES;
        }
    }
}

- (NSTimer *)talkAnimTimer {
    if (_talkAnimTimer == nil) {
        _talkAnimTimer = [NSTimer scheduledTimerWithTimeInterval:0.5f target:self selector:@selector(talkAnimation) userInfo:nil repeats:YES];
    }
    
    return _talkAnimTimer;
}

- (void)releaseTalkAnimTimer {
    if (_talkAnimTimer.isValid) {
        [_talkAnimTimer invalidate];
        _talkAnimTimer = nil;
    }
}

- (void)talkAnimation {
    __block SHWaterView *waterView = [[SHWaterView alloc] initWithFrame:CGRectMake(0, 0, 120, 120)];
    waterView.center = _talkbackButton.center;
    waterView.strokeColor = [UIColor ic_colorWithHex:kButtonThemeColor]; //[UIColor colorWithRed:51/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
    waterView.radius = _talkbackButton.bounds.size.width * 0.5;
    
    waterView.backgroundColor = [UIColor clearColor];
    
//    [self.view addSubview:waterView];
    [self.view insertSubview:waterView belowSubview:_talkbackButton];
    
    [UIView animateWithDuration:2 animations:^{
        
        waterView.transform = CGAffineTransformScale(waterView.transform, 1.618, 1.618);
        
        waterView.alpha = 0;
        
    } completion:^(BOOL finished) {
        [waterView removeFromSuperview];
    }];
}

- (UIImage *)startOnImage {
    if (_startOnImage == nil) {
        _startOnImage = [UIImage imageNamed:@"stop_on"];
    }
    
    return _startOnImage;
}

- (UIImage *)startOffImage {
    if (_startOffImage == nil) {
        _startOffImage = [UIImage imageNamed:@"stop_off"];
    }
    
    return _startOffImage;
}

//处理双指事件
- (void)handleDoubleFingerEvent:(UITapGestureRecognizer *)sender
{
    if (sender.numberOfTapsRequired == 1) {
        //双指单击
//        NSLog(@"双指单击");
        if (self.videoCacheObserver == nil) {
            _videoCacheLabel.hidden = NO;
            _audioCacheLabel.hidden = NO;
            _videoCacheLabel.text = @"";
            _audioCacheLabel.text = @"";
            [self addPreviewCacheObserver];
        }
    }else if(sender.numberOfTapsRequired == 2){
        //双指双击
        NSLog(@"双指双击");
    }
}

- (IBAction)changeVideoSizeAction:(id)sender {
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self prepareVideoSizeData];
    
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];

            [self createVideoSizeTipsView];
        });
    });
}

- (void)createVideoSizeTipsView {
    self.videoSizeView =[[CustomIOS7AlertView alloc] initWithTitle:NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", nil) inView:self.view];
    UIView      *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 290, 150)];
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 10, 275, 130)
                                                          style:UITableViewStylePlain];
    [containerView addSubview:tableView];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _videoSizeView.containerView = containerView;
    [_videoSizeView setUseMotionEffects:TRUE];
    [_videoSizeView setButtonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"ALERT_CLOSE", @""), nil]];
    [_videoSizeView show];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _videoSizeData.detailData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    
    if (indexPath.row < _videoSizeData.detailData.count) {
        cell.textLabel.text = _videoSizeData.detailData[indexPath.row];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectVideoSizeAtIndexPath:indexPath];
    
    [_videoSizeView close];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _videoSizeData.detailLastItem) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

- (void)selectVideoSizeAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row != _videoSizeData.detailLastItem) {
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"STREAM_ERROR_CAPTURING_CAPTURE", nil)];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            SHVideoSize *vs = [SHVideoSize videoSizeWithCamera:_shCameraObj];
            NSString *value = _videoSizeData.detailOriginalData[indexPath.row];
            
            if ([vs changeVideoSize:value]) {
                
                _shCameraObj.cameraProperty.videoSizeData.detailTextLabel = value;
                _shCameraObj.cameraProperty.videoSizeData.detailLastItem = indexPath.row;
                
                [_shCameraObj.cameraProperty cleanCacheFormat];
                if (_shCameraObj.streamOper.PVRun) {
                    [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                        SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                        
                        [self startPreview];
                    }];
                }
                
                [self updateSizeItemTitle];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_SET_ERROR", nil) showTime:2.0];
                });
            }
        });
    }
}

- (void)prepareVideoSizeData {
    SHSettingData *vsData = nil;
    
    if (!_shCameraObj.cameraProperty.videoSizeData) {
        SHVideoSize *vs = [SHVideoSize videoSizeWithCamera:_shCameraObj];
        
        vsData = [vs prepareDataForVideoSize];
        _shCameraObj.cameraProperty.videoSizeData = vsData;
    } else {
        vsData = _shCameraObj.cameraProperty.videoSizeData;
    }
    
    if (vsData != nil) {
        _videoSizeData = vsData;
    }
    
    [self updateSizeItemTitle];
}

- (void)updateSizeItemTitle {
    if (_shCameraObj.cameraProperty.videoSizeData == nil) {
        return;
    }
    
    NSString *title = nil;
    NSArray *tempArray = [_shCameraObj.cameraProperty.videoSizeData.detailTextLabel componentsSeparatedByString:@" "];
    if (tempArray.count >= 3) {
        title = tempArray[2];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (title) {
            [self.recordButton setTitle:title forState:UIControlStateNormal];
        }
    });
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Property
- (void)initCameraPropertyGUI {
    [self initBatteryLevelIcon];
//    [self initWifiStatusIcon];
    
    SHICatchEvent *evt = _shCameraObj.cameraProperty.curBatteryLevel;
    evt ? [self updateBatteryLevelIcon:evt] : void();
    [self updateCameraPropertyGUI];
}

- (void)updateCameraPropertyGUI {
    __weak typeof(self) weakSelf = self;
    
    [_shCameraObj setCameraPropertyValueChangeBlock:^ (SHICatchEvent *evt){
        switch (evt.eventID) {
            case ICATCH_EVENT_BATTERY_LEVEL_CHANGED:
                weakSelf.shCameraObj.cameraProperty.curBatteryLevel = evt;
                [weakSelf updateBatteryLevelIcon:evt];
                break;
                
            case ICATCH_EVENT_WIFI_SIGNAL_LEVEL_CHANGED:
                [weakSelf updateWifiStatusIcon:evt];
                break;
            default:
                break;
        }
    }];
}

- (void)initBatteryLevelIcon {
    uint level = [_shCameraObj.controler.propCtrl prepareDataForBatteryLevelWithCamera:_shCameraObj andCurResult:_shCameraObj.curResult];
    NSString *imageName = [_shCameraObj.controler.propCtrl transBatteryLevel2NStr:level];
    UIImage *batteryStatusImage = [UIImage imageNamed:imageName];
    self.batteryImgView.image = batteryStatusImage;
    self.batteryLowAlertShowed = NO;
    _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];
}

- (void)updateBatteryLevelIcon:(SHICatchEvent *)evt {
    int level = evt.intValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *imageName = [_shCameraObj.controler.propCtrl transBatteryLevel2NStr:level];
        UIImage *batteryStatusImage = [UIImage imageNamed:imageName];
        self.batteryImgView.image = batteryStatusImage;
        _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];

        if ([imageName isEqualToString:@"ic_battery_alert_24dp"] && !_batteryLowAlertShowed) {
            self.batteryLowAlertShowed = YES;
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"ALERT_LOW_BATTERY", nil) showTime:2.0];
            
        } else if ([imageName isEqualToString:@"ic_battery_charging_green_24dp"]) {
            self.batteryLowAlertShowed = NO;
        }
    });
}

- (void)initWifiStatusIcon {
    NSString *imageName = [_shCameraObj.controler.propCtrl prepareDataForWifiStatusWithCamera:_shCameraObj andCurResult:_shCameraObj.curResult];
    UIImage *wifiStatusImage = [UIImage imageNamed:imageName];
    self.wifiStatusImgView.image = wifiStatusImage;
}

- (void)updateWifiStatusIcon:(SHICatchEvent *)evt {
    int statusValue = evt.intValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *imageName = [_shCameraObj.controler.propCtrl transWifiStatus2NStr:statusValue];
        UIImage *wifiStatusImage = [UIImage imageNamed:imageName];
        self.wifiStatusImgView.image = wifiStatusImage;
    });
}

#pragma mark - CurrentDate
- (NSTimer *)currentDateTimer {
    if (_currentDateTimer == nil) {
        _currentDateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(updateCurrentDate) userInfo:nil repeats:YES];
    }
    
    [self updateCurrentDate];
    
    return _currentDateTimer;
}

- (void)releaseCurrentDateTimer {
    if (_currentDateTimer.isValid) {
        [_currentDateTimer invalidate];
        _currentDateTimer = nil;
    }
}

- (void)updateCurrentDate {
     NSDateFormatter *formatter = [[NSDateFormatter alloc ] init];
     [formatter setDateFormat:@"yyyy/MM/dd HH:mm"];

    NSString *timeNow = [formatter stringFromDate:[NSDate date]];
    
    WEAK_SELF(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        weakself.timeLabel.text = timeNow;
    });
}

#pragma mark - Video Bitrate Observer
- (void)addVideoBitRateObserver {
    SHSDKEventListener *bitRateListener = new SHSDKEventListener(self, @selector(updateBitRateInfo:));
    self.bitRateObserver = [SHObserver cameraObserverWithListener:bitRateListener eventType:ICATCH_EVENT_VIDEO_BITRATE isCustomized:NO isGlobal:NO];
    [_shCameraObj.sdk addObserver:self.bitRateObserver];
}

- (void)removeVideoBitRateObserver {
    if (self.bitRateObserver) {
        [_shCameraObj.sdk removeObserver:self.bitRateObserver];
        
        if (self.bitRateObserver.listener) {
            delete self.bitRateObserver.listener;
            self.bitRateObserver.listener = nullptr;
        }
        
        self.bitRateObserver = nil;
    }
}

- (void)updateBitRateInfo:(SHICatchEvent *)evt {    
    switch (evt.eventID) {
        case ICATCH_EVENT_VIDEO_BITRATE:
            [self updateBitRateLabel:evt.doubleValue1 + evt.doubleValue2];
            break;
            
        default:
            break;
    }
}

- (void)updateBitRateLabel:(CGFloat)value {
    dispatch_async(dispatch_get_main_queue(), ^{
        _bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", (int)value];
    });
}

- (void)enableUserInteraction:(BOOL)enable {
    _muteButton.enabled = enable;
    _talkbackButton.enabled = enable;
    _captureButton.enabled = enable;
    _pvFailedLabel.hidden = enable;
    _pvFailedLabel.text = enable ? nil : NSLocalizedString(@"StartPVFailed", nil);
}

@end
