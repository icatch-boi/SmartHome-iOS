// SHCameraPreviewVC.m

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
 
 // Created by zj on 2018/3/22 上午11:13.
    

#import "SHCameraPreviewVC.h"
#import "SHCameraPreviewVCPrivateHeader.h"
#import "SHWaterView.h"
#import "SH_XJ_SettingTVC.h"
#import "SHICatchEvent.h"
#import "SHSinglePreviewVC.h"
#import "RTCView.h"
#import "RTCButton.h"
#import "SHNetworkManagerHeader.h"
#import "SHLocalWithRemoteHelper.h"
#import "SHLocalCamerasHelper.h"
#import "SHSDKEventListener.hpp"
#import <unistd.h>
#import "AppDelegate.h"
#import "SDAutoLayout.h"
#import "SHDownloadManager.h"

#define ENABLE_AUDIO_BITRATE 0

static NSString * const kPreviewStoryboardID = @"PreviewStoryboardID";
static const CGFloat kSpeakerTopConsDefaultValue = 50;
static const CGFloat kSpeakerTopConsDefaultValue_Special = 6;
static const CGFloat kSpeakerLeftConsDefaultValue = 40;
static const CGFloat kAudioBtnDefaultWidth = 60;
static const CGFloat kSpeakerBtnDefaultWidth = 80;
static const NSTimeInterval kRingTimeout = 50.0;
static const NSTimeInterval kConnectAndPreviewTimeout = 120.0;
static const NSTimeInterval kConnectAndPreviewSpecialSleepTime = 5.0;
static const NSTimeInterval kConnectAndPreviewCommonSleepTime = 1.0;

@interface SHCameraPreviewVC () <UITableViewDelegate, UITableViewDataSource, SH_XJ_SettingTVCDelegate, SHSinglePreviewVCDelegate, HWOptionButtonDelegate>

@property (nonatomic, strong) SHSettingData *videoSizeData;
@property (nonatomic, assign) BOOL disconnectHandling;
@property (nonatomic, assign) BOOL poweroffHandling;
@property (nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;
@property (nonatomic, strong) NSTimer *currentDateTimer;

@property (nonatomic, weak) RTCView *presentView;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic) SHObserver *bitRateObserver;

@property (nonatomic, strong) NSTimer *ringTimer;

@property (nonatomic, strong) NSTimer *connectAndPreviewTimer;
@property (nonatomic, assign) BOOL connectAndPreviewTimeout;
@property (nonatomic, assign) NSUInteger connectTimes;
@property (nonatomic, strong) MBProgressHUD *progressHUDPreview;
@property (nonatomic, assign) BOOL alreadyBack;

@end

@implementation SHCameraPreviewVC

+ (instancetype)cameraPreviewVC {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"XJMain" bundle:nil];
    SHCameraPreviewVC *vc = [sb instantiateViewControllerWithIdentifier:kPreviewStoryboardID];
    vc.edgesForExtendedLayout = UIRectEdgeNone;
    
    return vc;
}

#pragma mark - Init Variable
- (void)initParameter {
    _shCameraObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid];
    _ctrl = _shCameraObj.controler;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initParameter];
//    [self clickNotificationHandle];
    [self setupGUI];
    [self constructPreviewData];
//    [self prepareVideoSizeData];
//    [self prepareCameraPropertyData];
    [self addTapGesture];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTitle];
//    [self prepareVideoSizeData];
    [self setupCallView];
    [self updateResolutionButton:_shCameraObj.streamQuality];
#if 0
    if (!_shCameraObj.isConnect) {
        [self.progressHUD showProgressHUDWithMessage:NSLocalizedString(@"kConnecting", @"")];
        dispatch_async(self.previewQueue, ^{
            [self connectCamera];
            
            if (_shCameraObj.isConnect) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initPlayer];
                    [self startPreview];
                });
            }
        });
    } else {
        [self initPlayer];
        
        if (_managedObjectContext) {
            NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
            if (![msgType isEqualToString:@"201"]) {
                [self startPreview];
            }
        } else {
            [self startPreview];
        }
    }
#endif
#if 0
    [self connectAndPreview];
#else
    BOOL isRing = _managedObjectContext && [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"];
    if (!isRing) {
        [self connectAndPreview];
    }
#endif
#if 0
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
#endif
    
//    [self currentDateTimer];
    self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
    [self.shCameraObj.cameraProperty addObserver:self forKeyPath:@"serverOpened" options:NSKeyValueObservingOptionNew context:nil];
    [self updateTalkState];
    [self.previewImageView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self initCameraPropertyGUI];
//    [self checkLoginStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
//    [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
//    [self.previewImageView  removeObserver:self forKeyPath:@"bounds"];
    
    [super viewWillDisappear:animated];
    
//    if (_TalkBackRun) {
//        [self talkBackAction:nil];
//    }
    [self releaseTalkAnimTimer];
    [self releaseConectAndPreview];
    [self releaseRingTimer];
    
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:nil];
    [self.avslayer removeFromSuperlayer];
    [self closeCallView];
    [self stopPlayRing];
    _notification = nil;
    _managedObjectContext = nil;
    
    UIImage *image = [_shCameraObj.streamOper getLastFrameImage];
    if (image != nil) {
        _previewImageView.image = image;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
//    [self removeVideoBitRateObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseCurrentDateTimer];
//    [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
//    [self.previewImageView  removeObserver:self forKeyPath:@"bounds"];
    @try {
        [self.previewImageView  removeObserver:self forKeyPath:@"bounds"];
    } @catch (NSException *exception) {
        SHLogError(SHLogTagAPP, @"remove observer happen exception: %@", exception);
    } @finally {
        
    }
    @try {
        [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
    } @catch (NSException *exception) {
        SHLogError(SHLogTagAPP, @"remove observer happen exception: %@", exception);
    } @finally {
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    SHLogInfo(SHLogTagAPP, @"%@ - dealloc", self.class);
    
    [self deconstructPreviewData];
}

#pragma mark - initPlayer & Play
- (void)initPlayer {
    [self setupSampleBufferDisplayLayer];
    
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:^(BOOL isBuffering, BOOL timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.previewImageView && isBuffering) {
                [self.bufferNotificationView showGCDNoteWithMessage:NSLocalizedString(@"PREVIEW_BUFFERING_INFO", nil) andTime:1.0 withAcvity:NO];
            }
        });
    }];
    [self setMuteButtonBackgroundImage];
}

- (void)connectCamera {
    int retValue = [_shCameraObj connectCamera];
    
    if (retValue != ICH_SUCCEED) {
        NSString *name = _shCameraObj.camera.cameraName;
        NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
        NSString *errorInfo = @"";
        errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
        errorInfo = [errorInfo stringByAppendingString:/*@"确定要退出Preview吗 ?"*/NSLocalizedString(@"kExitPreview", nil)];

        UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
        
        WEAK_SELF(self);
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
                [weakself enableUserInteraction:NO];
            });
        }]];
        [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakself.progressHUD hideProgressHUD:YES];
//                [weakself.navigationController popViewControllerAnimated:YES];
                [weakself goHome];
            });
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertC animated:YES completion:nil];
        });
    } else {
//        [_shCameraObj initCamera];
    }
}

- (void)startMediaStream {
    [self.progressHUDPreview showProgressHUDWithMessage:NSLocalizedString(@"kStartStream", nil)];

    [_shCameraObj.streamOper startMediaStreamWithEnableAudio:YES file:nil successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
#if 0
            [self isRing] ? (_shCameraObj.cameraProperty.serverOpened ? [self talkBackAction:_speakerButton] : void()) : [self.progressHUD hideProgressHUD:YES];
#endif
            [self.progressHUDPreview hideProgressHUD:YES];
//            [self isRing] ? (_shCameraObj.cameraProperty.serverOpened ? [self talkBackAction:_speakerButton] : void()) : void();
            [self isRing] ? [self talkBackAction:_speakerButton] : void();
            //            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self enableUserInteraction:YES];
            [self prepareCameraPropertyData];
        });
        
        //        NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
        //        if ([msgType isEqualToString:@"201"]) {
        //            if (_shCameraObj.controler.actCtrl.isRecord == NO) {
        //                [self startVideoRec];
        //            }
        //        }
        
//        [_shCameraObj initCamera];
        
        [_shCameraObj initCamera];
        [self releaseConectAndPreview];
//        [self addVideoBitRateObserver];
        [self addDeviceObserver];
    } failedBlock:^(NSInteger errorCode) {
#if 0
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *notice = NSLocalizedString(@"StartPVFailed", nil);
            if (errorCode == ICH_PREVIEWING_BY_OTHERS) {
                notice = NSLocalizedString(@"kPreviewingByOthers", nil); //@"Previewing by others";
            } else if (errorCode == ICH_PLAYING_VIDEO_BY_OTHERS) {
                notice = NSLocalizedString(@"kPlayingVideoByOthers", nil); //@"Playing video by others";
            }
            [self.progressHUD showProgressHUDNotice:notice showTime:2.0];
            [self enableUserInteraction:NO];
        });
#else
        [self reConnectWithSleepForTimeInterval:kConnectAndPreviewCommonSleepTime];
#endif
        
//        [_shCameraObj initCamera];
    } target:nil streamCloseCallback:nil];
}

- (void)startPreview {
    if (!_shCameraObj.streamOper.PVRun) {
        [self startMediaStream];
    } else {
//        [self addVideoBitRateObserver];
        [self addDeviceObserver];
        [self prepareCameraPropertyData];
    }
}

- (void)prepareCameraPropertyData {
    if (_shCameraObj.isConnect) {
        [self initCameraPropertyGUI];
//        [self prepareVideoSizeData];
    }
}

- (void)clickNotificationHandle {
    if (_managedObjectContext) {
        if (!_shCameraObj.isConnect) {
            [self.progressHUD showProgressHUDWithMessage:nil];
            
            dispatch_async(self.previewQueue, ^{
                [self connectCamera];
                
                if (_shCameraObj.isConnect) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initPlayer];
                        [self updateTitle];
//                        [self prepareCameraPropertyData];
                        
                        [self startPreview];
                    });
//                    [self startPreview];
//                    NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
//                    if (![msgType isEqualToString:@"201"]) {
//                        [self startPreview];
//                    } else {
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            [self.progressHUD hideProgressHUD:YES];
//                        });
//                    }
                }
            });
        }
    }
}

- (void)checkLoginStatus {
#if 0
    if ([SHNetworkManager sharedNetworkManager].userLogin) {
        if ([SHCameraManager sharedCameraManger].smarthomeCams.count) {
            [self clickNotificationHandle];
        } else {
            [self syncData];
        }
    } else {
        [self loginPrompt];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
    }
#endif
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
        if (!isSuccess) {
            [weakself loginPrompt];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
        }
    }];
}

- (void)loginPrompt {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:/*@"用户登录已过期，请重新登录."*/NSLocalizedString(@"kAccountLoginExpired", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:/*@"登录"*/NSLocalizedString(@"kLogin", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself stopPlayRing];
        //        [weakself closeCallView];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserShouldLoginNotification object:nil];
    }]];
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)loginSuccess {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginSuccessNotification object:nil];

//    [self syncData];
}

- (void)syncData {
    if (_managedObjectContext == nil) {
        return;
    }
    
    [self.progressHUD showProgressHUDWithMessage:nil];
    [SHLocalWithRemoteHelper syncCameraList:^(BOOL isSuccess) {
        [self loadData];
    }];
}

- (void)loadData {
    [[[SHLocalCamerasHelper alloc] init] prepareCamerasData];
    
    [self initParameter];
    if (_shCameraObj == nil) {
        [self deviceHasRemovedPrompt];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
        });
    } else {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self setupCallView];
//        });
//        [self startPlayRing];
        [self clickNotificationHandle];
    }
}

- (void)deviceHasRemovedPrompt {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"此设备已被移除." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self goHome];
    }]];
    [self presentViewController:alertC animated:YES completion:nil];
}

#pragma mark - Init Preview GUI
- (void)updateTitle {
    NSString *mode = [_shCameraObj.sdk getTutkConnectMode];
    NSString *temp = mode ? [NSString stringWithFormat:@"%@ : %@", _shCameraObj.camera.cameraName, mode] :  _shCameraObj.camera.cameraName;
    self.title = temp;
}

- (void)updateTalkState {
    _TalkBackRun =  _shCameraObj.cameraProperty.talk ;
    
    if (_TalkBackRun) {
        [self talkAnimTimer];
    }
}

- (void)setupGUI {
//    [_audioButton setCornerWithRadius:_audioButton.bounds.size.width * 0.5];
//    [_captureButton setCornerWithRadius:_captureButton.bounds.size.width * 0.5];
//    [_speakerButton setCornerWithRadius:_speakerButton.bounds.size.width * 0.5];
//    [_videoSizeButton setCornerWithRadius:_videoSizeButton.bounds.size.width * 0.15];
    
//    self.speakerButton.backgroundColor = [UIColor lightGrayColor];
//    self.captureButton.backgroundColor = [UIColor lightGrayColor];
//    self.audioButton.backgroundColor = [UIColor lightGrayColor];
//    self.videoSizeButton.backgroundColor = [UIColor lightGrayColor];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-back"] style:UIBarButtonItemStyleDone target:self action:@selector(returnBack)];
    self.navigationItem.rightBarButtonItem = _notification ? nil : [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-setting"] style:UIBarButtonItemStyleDone target:self action:@selector(enterSettingAction)];
    
    _speakerTopCons.constant = (kScreenHeightScale == 1.0) ? kSpeakerTopConsDefaultValue_Special : kSpeakerTopConsDefaultValue * kScreenHeightScale;
    _speakerLeftCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _speakerRightCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _audioBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    _speakerBtnWidthCons.constant = kSpeakerBtnDefaultWidth * kScreenWidthScale;
    _captureBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    
    UIImage *img = _shCameraObj.camera.thumbnail;
//    img = img ? img : [UIImage imageNamed:@"default_thumb"];
    _previewImageView.image = img; //[img ic_imageWithSize:_previewImageView.bounds.size backColor:self.view.backgroundColor];
    _bitRateLabel.text = @"0kb/s"; //[NSString stringWithFormat:@"%dkb/s", 100 + (arc4random() % 100)];
#if 0
    [self setupTopToolView];
    [self setupBottomToolView];
#endif
    [self enableUserInteraction:NO];
    [self setupResolutionButton];
}

- (void)setupSampleBufferDisplayLayer {
    AVSampleBufferDisplayLayer *avslayer = _shCameraObj.cameraProperty.avslayer;
    if (avslayer == nil) {
        avslayer = [[AVSampleBufferDisplayLayer alloc] init];
        _shCameraObj.cameraProperty.avslayer = avslayer;
    }
    
    CGRect avslayerFrame;
    if (_shCameraObj.cameraProperty.avslayerFrame.size.width && _shCameraObj.cameraProperty.avslayerFrame.size.height) {
        avslayerFrame = _shCameraObj.cameraProperty.avslayerFrame;
    } else {
        avslayerFrame = [self calcAVSlayerBounds];
        _shCameraObj.cameraProperty.avslayerFrame = avslayerFrame;
    }
    
    avslayer.bounds = avslayerFrame;
    avslayer.position = CGPointMake(CGRectGetMidX(avslayerFrame), CGRectGetMidY(avslayerFrame));
    avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avslayer.backgroundColor = [[UIColor blackColor] CGColor];
    
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    avslayer.controlTimebase = controlTimebase;
    
    CMTimebaseSetRate(avslayer.controlTimebase, 1.0);
    
    self.avslayer = avslayer;
    
    [self.previewImageView.layer addSublayer:self.avslayer];
}

- (CGRect)calcAVSlayerBounds {
    CGFloat screenW = [UIScreen screenWidth];
    CGFloat screenH = [UIScreen screenHeight];
    CGFloat avslayerW = screenW;
    
    if (screenW > screenH) {
        avslayerW = screenH;
    }

    CGFloat avslayerH = avslayerW * 9 / 16;
    CGRect avslayerFrame = CGRectMake(0, 0, avslayerW, avslayerH);

    return avslayerFrame;
}

- (void)constructPreviewData {
    NSString *stillCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"Capture_Shutter" ofType:@"WAV"];
    id url = [NSURL fileURLWithPath:stillCaptureSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_stillCaptureSound);
    
//    NSString *videoCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"StartStopVideoRec" ofType:@"WAV"];
//    url = [NSURL fileURLWithPath:videoCaptureSoundUri];
//    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_videoCaptureSound);
}

- (void)deconstructPreviewData {
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
//    AudioServicesDisposeSystemSoundID(_videoCaptureSound);
}

#pragma mark - Property
- (void)initCameraPropertyGUI {
    [self initBatteryLevelIcon];
    
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

            case ICATCH_EVENT_PV_THUMBNAIL_CHANGED:
                SHLogInfo(SHLogTagAPP, @"receive ICATCH_EVENT_PV_THUMBNAIL_CHANGED");
                //do get thumbnail
//                [weakSelf updatePvThumbnail:evt];
                break;
                
            case ICATCH_EVENT_VIDEO_BITRATE:
                [weakSelf updateBitRateLabel:evt.doubleValue1 + evt.doubleValue2];
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
    self.batteryImageView.image = batteryStatusImage;
    self.batteryLowAlertShowed = NO;
    _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];
    
    self.batteryInfoLabel.text = [NSString stringWithFormat:@"%d%%", level];
    self.batteryInfoImgView.image = batteryStatusImage;
}

- (void)updateBatteryLevelIcon:(SHICatchEvent *)evt {
    int level = evt.intValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *imageName = [_shCameraObj.controler.propCtrl transBatteryLevel2NStr:level];
        UIImage *batteryStatusImage = [UIImage imageNamed:imageName];
        self.batteryImageView.image = batteryStatusImage;
        _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];

        self.batteryInfoLabel.text = [NSString stringWithFormat:@"%d%%", level];
        self.batteryInfoImgView.image = batteryStatusImage;
        
        if ([imageName isEqualToString:@"vedieo-buttery"] && !_batteryLowAlertShowed) {
            self.batteryLowAlertShowed = YES;
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"ALERT_LOW_BATTERY", nil) showTime:2.0];
            
        } else if ([imageName isEqualToString:@"vedieo-buttery_2"]) {
            self.batteryLowAlertShowed = NO;
        }
    });
}

- (void)updatePvThumbnail:(SHICatchEvent *)evt {
    NSString *pvTime = evt.stringValue1;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"before set, lastPreviewTime is : %@", self.shCameraObj.camera.pvTime);
        
        [self.shCameraObj updatePreviewThumbnailWithPvTime:pvTime];
        dispatch_async(dispatch_get_main_queue(),^(void){

            NSLog(@"lastPreviewTime is : %@", self.shCameraObj.camera.pvTime);
        });
    });
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
            [self.videoSizeButton setTitle:title forState:UIControlStateNormal];
        }
    });
}

#pragma mark - Action
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

- (IBAction)talkBackAction:(id)sender {
    SHLogTRACE();
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        if (_TalkBackRun /*&& interval > 1.0*/) {
            _TalkBackRun = NO;
            
            [self stopTalkBack];
            _noHidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
//                self.speakerButton.backgroundColor = [UIColor lightGrayColor];
                [self setMuteButtonBackgroundImage];
            });
        }
        
//        [self voiceDidCancelRecording];
//        [self setNeedsUpdateTalkIcon:NO];
    } else {
        [self checkAudioStatus:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.speakerButton.enabled = YES;
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
                self.speakerButton.enabled = NO;
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
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            
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
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            
            //            [self voiceDidCancelRecording];
            [self releaseTalkAnimTimer];
            
            _shCameraObj.cameraProperty.talk = NO;
            _TalkBackRun = NO;
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
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self.progressHUD hideProgressHUD:YES];
            
            _speakerButton.enabled = YES;
            _noHidden = NO;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            SHLogInfo(SHLogTagAPP, @"Failed to stop talkBack");
//            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStopTalkBackFailed", @"") showTime:2.0];
            
            _speakerButton.enabled = YES;
            _TalkBackRun = YES;
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
            [self.progressHUD showProgressHUDNotice:/*@"Capture success"*/NSLocalizedString(@"kCaptureSuccess", nil) showTime:1.0];
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_CAPTURE_FAILED", nil) showTime:1.5];
        });
    }];
#endif
}

- (IBAction)toggleAudioAction:(UIButton *)sender {
    SHLogTRACE();

//    [self.progressHUD showProgressHUDWithMessage:nil];
    [_shCameraObj.streamOper isMute:sender.tag successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sender.tag == 0) {
                sender.tag = 1;
                [sender setImage:[UIImage imageNamed:@"video-btn-mute"]
                        forState:UIControlStateNormal];
                [sender setImage:[UIImage imageNamed:@"video-btn-mute-pre"] forState:UIControlStateHighlighted];
            } else {
                sender.tag = 0;
                [sender setImage:[UIImage imageNamed:@"video-btn-mute_1"]
                        forState:UIControlStateNormal];
                [sender setImage:[UIImage imageNamed:@"video-btn-mute-pre_1"]
                        forState:UIControlStateHighlighted];
            }
            
//            [self.progressHUD hideProgressHUD:YES];
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kAudioControl", @"") showTime:2.0];
        });
    }];
}

- (IBAction)changeVideoSizeAction:(id)sender {
#if 0
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self prepareVideoSizeData];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            
            [self createVideoSizeTipsView];
        });
    });
#endif
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

- (void)enterSettingAction {
    SHLogTRACE();
    
    UIViewController *vc = [self prepareSettingViewController];
    
    if (_shCameraObj.streamOper.PVRun) {
        [self.progressHUD showProgressHUDWithMessage:nil];

        dispatch_async(/*self.previewQueue*/dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self stopCurrentTalkBack];
            
            [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
//                    [self presentSettingViewController];
                    [self presentViewController:vc animated:YES completion:nil];
                });
            }];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];

//            [self presentSettingViewController];
            [self presentViewController:vc animated:YES completion:nil];
        });
    }
}

- (UIViewController *)prepareSettingViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    UINavigationController *navController = [sb instantiateViewControllerWithIdentifier:@"SettingStoryboardID"];
    SH_XJ_SettingTVC *vc = (SH_XJ_SettingTVC *)navController.topViewController;
    vc.cameraUid = _cameraUid;
    vc.delegate = self;
    [SHTool configureAppThemeWithController:navController];
    
//    [self presentViewController:navController animated:YES completion:nil];
    return navController;
}

- (void)stopCurrentTalkBack {
    if (_TalkBackRun) {
        _TalkBackRun = NO;
        _shCameraObj.cameraProperty.talk = NO;
        [_shCameraObj.streamOper stopTalkBack];
        [self releaseTalkAnimTimer];
    }
    
    @try {
        [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
    } @catch (NSException *exception) {
        SHLogError(SHLogTagAPP, @"remove observer happen exception: %@", exception);
    } @finally {
        
    }
}

- (void)returnBack {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraDisconnectNotification object:nil];
    _alreadyBack = YES;
#if 0
    if (!_shCameraObj.isConnect) {
        [self goHome];
        return;
    }
#endif
    
    UINavigationController *nav = self.navigationController;
    NSLog(@"==> nav : %@", nav);
    BOOL doNotDisconnect = /*_managedObjectContext &&*/ ![NSStringFromClass(nav.class) isEqualToString:@"SHMainViewController"];
#if 0
    NSString *message = [NSString stringWithFormat:@"%@...", NSLocalizedString(@"kDisconnect", @"")];
    if (doNotDisconnect) {
        message = nil;
    }
    [self.progressHUD showProgressHUDWithMessage:message];
    dispatch_async(self.previewQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self.navigationController popViewControllerAnimated:YES];
            [self goHome];
        });
        
        [self stopCurrentTalkBack];
        /*
        if (_shCameraObj.controler.actCtrl.isRecord) {
            [_shCameraObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
        }*/
        
        if (doNotDisconnect) {
            if (_shCameraObj.streamOper.PVRun) {
                [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                    SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                }];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
                
//                [self.navigationController popViewControllerAnimated:YES];
            });
            return;
        }
        
        [_shCameraObj.streamOper stopPreview];
//        sleep(2);
        [_shCameraObj.sdk disableTutk];
        [_shCameraObj disConnectWithSuccessBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
                
//                [self.navigationController popViewControllerAnimated:YES];
            });
        } failedBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kDisconnectTimeout", @"") showTime:2.0];
                
//                [self.navigationController popViewControllerAnimated:YES];
            });
        }];
    });
#else
    if (doNotDisconnect == NO && [self isDownloading]) {
        [self showDownloadingAlertView:doNotDisconnect];
    } else {
        [self returnBackHandle:doNotDisconnect];
    }
#endif
}

- (void)showDownloadingAlertView:(BOOL)doNotDisconnect {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:/*@"Tips"*/NSLocalizedString(@"Tips", nil) message:/*@"Some files are being downloaded, exiting preview will cancel the download, are you sure you want to quit ?"*/NSLocalizedString(@"kDownloadingSureQuitPreview", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"Cancle"*/NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:/*@"Sure"*/NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [weakself returnBackHandle:doNotDisconnect];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (BOOL)isDownloading {
    NSMutableArray *downloadList = [SHDownloadManager shareDownloadManger].downloadArray;
    if (downloadList != nil && downloadList.count > 0) {
        SHLogInfo(SHLogTagAPP, @"current download file num: %lu", (unsigned long)downloadList.count);
        return YES;
    } else {
        return NO;
    }
}

- (void)returnBackHandle:(BOOL)doNotDisconnect {
    NSString *message = [NSString stringWithFormat:@"%@...", NSLocalizedString(@"kDisconnect", @"")];
    if (doNotDisconnect) {
        message = nil;
    }
    [self.progressHUDPreview hideProgressHUD:YES];
    [self.progressHUD showProgressHUDWithMessage:message];
    dispatch_async(self.previewQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //            [self.navigationController popViewControllerAnimated:YES];
#if 0
            [self goHome];
#else
            if (doNotDisconnect == NO) {
                [self goHome];
            }
#endif
        });
        
        [self stopCurrentTalkBack];
        /*
         if (_shCameraObj.controler.actCtrl.isRecord) {
         [_shCameraObj.controler.actCtrl stopVideoRecWithSuccessBlock:nil failedBlock:nil];
         }*/
        
        if (doNotDisconnect) {
            if (_shCameraObj.streamOper.PVRun) {
                [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                    SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                }];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
                
                //                [self.navigationController popViewControllerAnimated:YES];
                [self goHome];
            });
            return;
        }
        
        [_shCameraObj.streamOper stopPreview];
        //        sleep(2);
        [_shCameraObj.sdk disableTutk];
        [_shCameraObj disConnectWithSuccessBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
                
                //                [self.navigationController popViewControllerAnimated:YES];
            });
        } failedBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kDisconnectTimeout", @"") showTime:2.0];
                
                //                [self.navigationController popViewControllerAnimated:YES];
            });
        }];
    });
}

- (void)setMuteButtonBackgroundImage {
    _audioButton.tag = _shCameraObj.cameraProperty.isMute;
    if (_audioButton.tag) {
        [_audioButton setImage:[UIImage imageNamed:@"video-btn-mute"] forState:UIControlStateNormal];
        [_audioButton setImage:[UIImage imageNamed:@"video-btn-mute-pre"] forState:UIControlStateHighlighted];
    } else {
        [_audioButton setImage:[UIImage imageNamed:@"video-btn-mute_1"] forState:UIControlStateNormal];
        [_audioButton setImage:[UIImage imageNamed:@"video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
    }
}

- (IBAction)enterFullScreenAction:(id)sender {
#if 1
    dispatch_async(self.previewQueue, ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"XJMain" bundle:nil];
        SHSinglePreviewVC *vc = [sb instantiateViewControllerWithIdentifier:@"SinglePreviewID"];
        vc.cameraUid = _shCameraObj.camera.cameraUid;
        vc.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
            app.isFullScreenPV = YES;
            
            [self presentViewController:vc animated:YES completion:nil];
        });
    });
#else
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        [self fullScreenHandler];
    } else {
        dispatch_async(self.previewQueue, ^{
            UIStoryboard *sb = [UIStoryboard storyboardWithName:@"XJMain" bundle:nil];
            SHSinglePreviewVC *vc = [sb instantiateViewControllerWithIdentifier:@"SinglePreviewID"];
            vc.cameraUid = _shCameraObj.camera.cameraUid;
            vc.delegate = self;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
                app.isFullScreenPV = YES;
                
                [self presentViewController:vc animated:YES completion:nil];
            });
        });
    }
#endif
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

#pragma mark - DisconnectHandle
- (void)cameraDisconnectHandle:(NSNotification *)nc {
    if (_disconnectHandling) {
        return;
    }
    
    _notification = nil;
    _disconnectHandling = YES;
    SHCameraObject *shCamObj = nc.object;
    
    if (!shCamObj.isConnect) {
        return;
    }
    
    [self stopCurrentTalkBack];
    
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
    
    [self stopCurrentTalkBack];
    
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
            
            [weakself returnBack];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

#pragma mark - Disconnect & Reconnect
- (void)showDisconnectAlert:(SHCameraObject *)shCamObj {
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ %@", shCamObj.camera.cameraName, NSLocalizedString(@"kDisconnect", @"")] message:NSLocalizedString(@"kDisconnectTipsInfo", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    __weak typeof(self) weakSelf = self;
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Exit", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _disconnectHandling = NO;
            
            //            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            [self returnBack];
        });
    }]];
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"STREAM_RECONNECT", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf reconnect:shCamObj];
    }]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

- (void)reconnect:(SHCameraObject *)shCamObj {
    [self.progressHUDPreview showProgressHUDWithMessage:[NSString stringWithFormat:@"%@ %@...", shCamObj.camera.cameraName, NSLocalizedString(@"kReconnecting", @"")]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        int retValue = [shCamObj connectCamera];
        if (retValue == ICH_SUCCEED) {
//            [shCamObj initCamera];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUDPreview hideProgressHUD:YES];
                
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
            [self returnBack];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUDPreview hideProgressHUD:YES];
        [self presentViewController:alertVc animated:YES completion:nil];
    });
}

- (void)goHome {
    [_shCameraObj.streamOper updatePreviewThumbnail];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TalkAnimation
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
    waterView.center = _speakerButton.center;
    waterView.strokeColor = [UIColor ic_colorWithHex:kThemeColor]; //[UIColor colorWithRed:51/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
    waterView.radius = _speakerButton.bounds.size.width * 0.5;
    
    waterView.backgroundColor = [UIColor clearColor];
    
    //    [self.view addSubview:waterView];
    [self.view insertSubview:waterView belowSubview:_speakerButton];
    
    [UIView animateWithDuration:2 animations:^{
        
        waterView.transform = CGAffineTransformScale(waterView.transform, 1.618, 1.618);
        
        waterView.alpha = 0;
        
    } completion:^(BOOL finished) {
        [waterView removeFromSuperview];
    }];
}

#pragma mark - lazyLoad
- (dispatch_queue_t)previewQueue {
    if (_previewQueue == nil) {
        _previewQueue = dispatch_queue_create("SimglePreviewQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _previewQueue;
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
        _bufferNotificationView = [[GCDiscreetNotificationView alloc] initWithText:nil showActivity:NO inPresentationMode:GCDiscreetNotificationViewPresentationModeTop inView:self.previewImageView];
    }
    
    return _bufferNotificationView;
}

#pragma mark - Action Progress
- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        UIView *v = self.navigationController.view;
        if (v == nil) {
            v = self.view;
        }
        
        _progressHUD = [MBProgressHUD progressHUDWithView:v];
    }
    
    return _progressHUD;
}

- (MBProgressHUD *)progressHUDPreview {
    if (_progressHUDPreview == nil) {
        _progressHUDPreview = [MBProgressHUD progressHUDWithView:self.view];
    }
    
    return _progressHUDPreview;
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
        weakself.curDateLabel.text = timeNow;
    });
}

#pragma mark - SHSinglePreviewVCDelegate
- (void)disconnectHandle {
    [self goHome];
}

#pragma mark - CallView
- (void)setupCallView {
    NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
    if (_managedObjectContext && [msgType isEqualToString:@"201"] && _presentView == nil) {
        RTCView *presentView = [[RTCView alloc] initWithIsVideo:NO isCallee:YES inView:self.navigationController.view];
        self.presentView = presentView;
        
        [self.presentView.hangupBtn addTarget:self action:@selector(hangupClick) forControlEvents:UIControlEventTouchUpInside];
        [self.presentView.answerBtn addTarget:self action:@selector(answerClick) forControlEvents:UIControlEventTouchUpInside];
        
        [_presentView show];
        [self setPresentViewTitle];
        
        [self startPlayRing];
    }
}

- (void)setPresentViewTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        _presentView.portraitImageView.image = [UIImage imageNamed:@"caller ID display-logo"/*@"portrait-1.jpg"*/];
        _presentView.nickName = _shCameraObj.camera.cameraName;
        _presentView.connectText = @"等待连接...";
        _presentView.netTipText = @"当前网络良好";
    });
}

- (void)startPlayRing
{
    NSString *ringPath = [[NSBundle mainBundle] pathForResource:@"test.caf" ofType:nil];
#if 0
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;  // 加上这两句，否则声音会很小
    [audioSession setCategory :AVAudioSessionCategoryPlayback error:&err];
#endif
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:ringPath] error:nil];
    self.player.numberOfLoops = -1;
    [self.player prepareToPlay];
    [self.player play];
    
    [self ringTimer];
}

- (void)stopPlayRing
{
    [self.player stop];
    self.player = nil;
    
    [self releaseRingTimer];
}

- (void)hangupClick {
    [self stopPlayRing];
    
//    if (_shCameraObj.isConnect && !self.isConnected) {
//        [self.progressHUD showProgressHUDWithMessage:nil];
//        [_shCameraObj disConnectWithSuccessBlock:^{
//            [self goHome:nil];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.progressHUD hideProgressHUD:YES];
//            });
//        } failedBlock:^{
//            [self goHome:nil];
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.progressHUD hideProgressHUD:YES];
//            });
//        }];
//    } else {
//        [self goHome:nil];
//    }
    [self returnBack];
}

- (void)answerClick {
    [self stopPlayRing];
    
    [self closeCallView];
#if 0
    if (_shCameraObj.isConnect) {
        [self startPreview];
    } else {
        [self connectAndPreview];
    }
#else
    [self connectAndPreview];
#endif
    
    [self checkLoginStatus];
}

- (void)closeCallView {
    if (_presentView) {
        [UIView animateWithDuration:0.5f animations:^{
            self.presentView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.presentView removeFromSuperview];
        }];
        
        _presentView = nil;
    }
}

- (void)enableUserInteraction:(BOOL)enable {
    _funScreenButton.enabled = enable;
    _videoSizeButton.enabled = enable;
    _audioButton.enabled = enable;
    _speakerButton.enabled = enable;
    _captureButton.enabled = enable;
//    _pvFailedLabel.hidden = enable;
//    _pvFailedLabel.text = enable ? nil : NSLocalizedString(@"StartPVFailed", nil);
    self.navigationItem.rightBarButtonItem.enabled = enable;
}

- (void)connectAndPreview {
#if 0
    if (!_shCameraObj.isConnect) {
        NSString *message = _managedObjectContext ? nil : NSLocalizedString(@"kConnecting", @"");
        [self.progressHUD showProgressHUDWithMessage:message];
        
        dispatch_async(self.previewQueue, ^{
            [self connectCamera];
            
            if (_shCameraObj.isConnect) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self initPlayer];
                    [self updateTitle];
//                    [self prepareCameraPropertyData];
                    
#if 0
                    if (_managedObjectContext) {
                        NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
                        if ([msgType isEqualToString:@"201"]) {
                            [self.progressHUD hideProgressHUD:YES];
                        } else {
                            [self startPreview];
                        }
                    } else {
                        [self startPreview];
                    }
#endif
                    [self startPreview];
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
                    
                    if (_shCameraObj == nil ||
                        _shCameraObj.camera == nil ||
                        _shCameraObj.camera.cameraUid == nil) {
                        [self showConnectFailedAlertView];
                    }
                });
            }
        });
    } else {
        [self initPlayer];
        
#if 0
        if (_managedObjectContext) {
            NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
            if (![msgType isEqualToString:@"201"]) {
                [self startPreview];
            }
        } else {
            [self startPreview];
        }
#endif
        [self startPreview];
    }
#else
    [self connectAndPreviewHandler];
#endif
}

- (void)showConnectFailedAlertView {
    NSString *name = _shCameraObj.camera.cameraName;
    NSString *errorMessage = NSLocalizedString(@"kConnectionUnknownError", nil);
    NSString *errorInfo = [NSString stringWithFormat:@"[%@] %@", name ? name : @"", errorMessage];
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself goHome];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
#if 0
        _bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", (int)value];
        
        self.bitRateInfoLabel.text = [NSString stringWithFormat:@"%dkb/s", (int)value];
#else
        NSString *bitRate = [SHTool bitRateStringFromBits:value]; //[self humanReadableStringFromBit:value];
        
        self.bitRateLabel.text = bitRate;
        self.bitRateInfoLabel.text = bitRate;
#endif
    });
}

- (NSString *)humanReadableStringFromBit:(CGFloat)bitCount
{
    CGFloat numberOfBit = bitCount;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"kb", @"Mb", @"Gb", @"Tb", @"Pb", @"Eb", @"Zb", @"Yb", nil];
    
    while (numberOfBit > 1024) {
        numberOfBit /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%.1f%@/s", numberOfBit, [tokens objectAtIndex:multiplyFactor]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    SHLogInfo(SHLogTagAPP, @"Observer keyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"serverOpened"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
        });
        
#if 0
//        if (_shCameraObj.cameraProperty.serverOpened) {
            BOOL isRing = _managedObjectContext && [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"];
            isRing ? [self talkBackAction:_speakerButton] : void();
//        }
#endif
    } else if ([keyPath isEqualToString:@"bounds"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            
            self.avslayer.bounds = _previewImageView.bounds;
            self.avslayer.position = CGPointMake(CGRectGetMidX(_previewImageView.bounds), CGRectGetMidY(_previewImageView.bounds));
            
            [CATransaction commit];
        });
    }
}

- (BOOL)isRing {
    return _managedObjectContext && [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"];
}

#pragma mark - Interface Rotate Handle
- (void)shrinkScreenClick:(id)sender {
    [self shrinkScreenHandler];
}

- (void)fullScreenHandler {
#if 0
    [self setupFullScreen:YES];
    
    [self updateSubviewFrameForFullScreen];
    
    [self interfaceOrientation:[self getRotateOrientation]];
#else
    SHLogTRACE();
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (app.isFullScreenPV) {
            SHLogWarn(SHLogTagAPP, @"Current already is full screen pv.");
            return;
        }
        
        [self setupFullScreen:YES];
        
        [self updateSubviewFrameForFullScreen];
        
        [self interfaceOrientation:[self getRotateOrientation]];
    });
#endif
}

- (void)shrinkScreenHandler {
#if 0
    [self setupFullScreen:NO];
    
    [self updateSubviewFrameForShrinkScreen];
    
    [self interfaceOrientation:UIInterfaceOrientationPortrait];
#else
    SHLogTRACE();
    dispatch_async(dispatch_get_main_queue(), ^{
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if (app.isFullScreenPV == NO) {
            SHLogWarn(SHLogTagAPP, @"Current already is shrink screen pv.");
            return;
        }
        
        [self setupFullScreen:NO];
        
        [self updateSubviewFrameForShrinkScreen];
        
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
    });
#endif
}

- (UIInterfaceOrientation)getRotateOrientation {
#if 1
    UIDeviceOrientation duration = [[UIDevice currentDevice] orientation];
    
    if (duration == UIDeviceOrientationLandscapeLeft) {
        return UIInterfaceOrientationLandscapeLeft;
    } else if (duration == UIDeviceOrientationLandscapeRight) {
        return UIInterfaceOrientationLandscapeRight;
    }
    
    return UIInterfaceOrientationLandscapeLeft;
    
#else
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
        return orientation;
    }
    
    return UIInterfaceOrientationLandscapeLeft;
#endif
}

- (void)setupFullScreen:(BOOL)fullScreen {
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isFullScreenPV = fullScreen;
}

- (void)interfaceOrientation:(UIInterfaceOrientation)orientation
{
    //强制转换
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        //        [CATransaction setAnimationDuration:0.168];
        
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation * invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
        
        [CATransaction commit];
    }
}

- (void)updateSubviewFrameForFullScreen {
    self.previewImageView.sd_layout.leftSpaceToView(self.view, 0)
    .topSpaceToView(self.view, 0)
    .rightSpaceToView(self.view, 0)
    .bottomSpaceToView(self.view, 0);
    
    self.pvFailedLabel.sd_layout.centerXEqualToView(self.previewImageView)
    .centerYEqualToView(self.previewImageView);
    
    self.captureButton.sd_resetNewLayout.leftSpaceToView(self.speakerButton, 30)
    .rightSpaceToView(self.view, 24)
    .bottomSpaceToView(self.view, 22)
    .widthIs(60)
    .heightEqualToWidth();
    
    self.speakerButton.sd_resetNewLayout.leftSpaceToView(self.audioButton, 30)
    .rightSpaceToView(self.captureButton, 30)
    .centerYEqualToView(self.captureButton)
    .widthIs(80)
    .heightEqualToWidth();
    
    self.audioButton.sd_resetNewLayout.rightSpaceToView(self.speakerButton, 30)
    .centerYEqualToView(self.speakerButton)
    .widthRatioToView(self.captureButton, 1.0)
    .heightEqualToWidth();
    
    self.headerView.hidden = YES;
    self.footerView.hidden = YES;
    self.navigationController.navigationBar.hidden = YES;
    self.topToolView.hidden = NO;
    self.bottomToolView.hidden = NO;
}

- (void)updateSubviewFrameForShrinkScreen {
    self.previewImageView.sd_layout.topSpaceToView(self.headerView, 0)
    .bottomSpaceToView(self.footerView, 0);
    
    CGFloat topMargin = (UIScreen.screenWidth == 480) ? kSpeakerTopConsDefaultValue_Special : kSpeakerTopConsDefaultValue * 568 / 480.0;
    self.speakerButton.sd_resetNewLayout.topSpaceToView(self.footerView, topMargin/*44*/)
    .leftSpaceToView(self.audioButton, 40)
    .rightSpaceToView(self.captureButton, 40)
    .centerXEqualToView(self.view)
    .widthIs(80)
    .heightEqualToWidth();
    
    self.captureButton.sd_resetNewLayout.centerYEqualToView(self.speakerButton)
    .leftSpaceToView(self.speakerButton, 40);
    
    self.audioButton.sd_resetNewLayout.centerYEqualToView(self.speakerButton)
    .rightSpaceToView(self.speakerButton, 40);
    
    self.headerView.hidden = NO;
    self.footerView.hidden = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.topToolView.hidden = YES;
    self.bottomToolView.hidden = YES;
}

#pragma mark - Setup Top Tool View
- (void)setupTopToolView {
    UIView *topToolView = [[UIView alloc] init];
    
    topToolView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    topToolView.hidden = YES;
    
    [self.view addSubview:topToolView];
    
    topToolView.sd_layout.leftSpaceToView(self.view, 0)
    .topSpaceToView(self.view, 0)
    .rightSpaceToView(self.view, 0)
    .heightIs(44);
    
    self.topToolView = topToolView;
    
    [self setupCloseButton];
    [self setupTitleLabel];
    [self setupBatteryInfoImageView];
    [self setupBatteryInfoLabel];
}

- (void)setupCloseButton {
    UIButton *closeBtn = [[UIButton alloc] init];
    
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [closeBtn setImage:[UIImage imageNamed:@"nav-btn-back"] forState:UIControlStateNormal];
    [closeBtn setImage:[UIImage imageNamed:@"nav-btn-back"] forState:UIControlStateHighlighted];
    [closeBtn addTarget:self action:@selector(shrinkScreenClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.topToolView addSubview:closeBtn];
    
    closeBtn.sd_layout.leftSpaceToView(self.topToolView, 12)
    .topSpaceToView(self.topToolView, 0)
    .bottomSpaceToView(self.topToolView, 0)
    .widthEqualToHeight();
    
    self.topCloseBtn = closeBtn;
}

- (void)setupTitleLabel {
    UILabel *titleLable = [[UILabel alloc] init];
    
    titleLable.text = @"Camera Name";
    titleLable.textColor = [UIColor whiteColor];
    titleLable.font = [UIFont systemFontOfSize:18.0];
    
    [self.topToolView addSubview:titleLable];
    
    titleLable.sd_layout.topSpaceToView(self.topToolView, 0)
    .bottomSpaceToView(self.topToolView, 0)
    .centerXEqualToView(self.topToolView)
    .centerYEqualToView(self.topToolView);
    
    [titleLable setSingleLineAutoResizeWithMaxWidth:MAXFLOAT];
    
    self.topTitleLabel = titleLable;
}

- (void)setupBatteryInfoImageView {
    UIImageView *batteryInfoImgView = [[UIImageView alloc] init];
    
    batteryInfoImgView.image = [UIImage imageNamed:@"vedieo-buttery_2"];
    
    [self.topToolView addSubview:batteryInfoImgView];
    
    batteryInfoImgView.sd_layout.topSpaceToView(self.topToolView, 0)
    .rightSpaceToView(self.topToolView, 20)
    .bottomSpaceToView(self.topToolView, 0)
    .leftSpaceToView(self.batteryInfoLabel, -8)
    .widthEqualToHeight()
    .centerYEqualToView(self.topToolView);
    
    self.batteryInfoImgView = batteryInfoImgView;
}

- (void)setupBatteryInfoLabel {
    UILabel *batteryInfoLabel = [[UILabel alloc] init];
    
    batteryInfoLabel.font = [UIFont systemFontOfSize:17.0];
    CGFloat colorValue = 242 / 255.0;
    batteryInfoLabel.textColor = [UIColor colorWithRed:colorValue green:colorValue  blue:colorValue alpha:1.0];
    batteryInfoLabel.text = @"70%";
    
    [self.topToolView addSubview:batteryInfoLabel];
    
    batteryInfoLabel.sd_layout.topSpaceToView(self.topToolView, 0)
    .bottomSpaceToView(self.topToolView, 0)
    .centerYEqualToView(self.batteryInfoImgView)
    .rightSpaceToView(self.batteryInfoImgView, -8);
//    .autoWidthRatio(1.0);
    [batteryInfoLabel setSingleLineAutoResizeWithMaxWidth:MAXFLOAT];
    
    self.batteryInfoLabel = batteryInfoLabel;
}

#pragma mark - Setup Top Tool View
- (void)setupBottomToolView {
    UIView *bottomToolView = [[UIView alloc] init];
    
    bottomToolView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    bottomToolView.hidden = YES;
    
    [self.view addSubview:bottomToolView];
    
    bottomToolView.sd_layout.leftSpaceToView(self.view, 16)
    .bottomSpaceToView(self.view, 12)
    .heightIs(24)
    .widthIs(100);
    
    bottomToolView.sd_cornerRadius = @(5);
    
    self.bottomToolView = bottomToolView;
    
    [self setupBitRateInfoLable];
}

- (void)setupBitRateInfoLable {
    UILabel *bitRateInfoLabel = [[UILabel alloc] init];
    
    bitRateInfoLabel.font = [UIFont systemFontOfSize:17.0];
    CGFloat colorValue = 242 / 255.0;
    bitRateInfoLabel.textColor = [UIColor colorWithRed:colorValue green:colorValue  blue:colorValue alpha:1.0];
    bitRateInfoLabel.text = @"0kb/s"; //[NSString stringWithFormat:@"%dkb/s", 100 + (arc4random() % 100)];
    bitRateInfoLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.bottomToolView addSubview:bitRateInfoLabel];
    
    bitRateInfoLabel.sd_layout.leftSpaceToView(self.bottomToolView, 4)
    .rightSpaceToView(self.bottomToolView, 4)
    .topSpaceToView(self.bottomToolView, 0)
    .bottomSpaceToView(self.bottomToolView, 0);
    
    self.bitRateInfoLabel = bitRateInfoLabel;
}

#pragma mark - Update Subviews
- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.topTitleLabel.text = title;
}

- (void)addTapGesture {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controlManagement)];
    [self.view addGestureRecognizer:tap];
}

- (void)controlManagement {
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (app.isFullScreenPV == NO) {
        return;
    }
    
    if (_noHidden) {
        self.topToolView.hidden = NO;
        self.speakerButton.hidden = NO;
        self.captureButton.hidden = NO;
        self.audioButton.hidden = NO;
        self.bottomToolView.hidden = NO;
    } else {
        if (self.topToolView.isHidden) {
            self.topToolView.hidden = NO;
            self.speakerButton.hidden = NO;
            self.captureButton.hidden = NO;
            self.audioButton.hidden = NO;
            self.bottomToolView.hidden = NO;
        } else {
            self.topToolView.hidden = YES;
            self.speakerButton.hidden = YES;
            self.captureButton.hidden = YES;
            self.audioButton.hidden = YES;
            self.bottomToolView.hidden = YES;
        }
    }
}

#pragma mark - Ring Timer
- (NSTimer *)ringTimer {
    if (_ringTimer == nil) {
        _ringTimer = [NSTimer scheduledTimerWithTimeInterval:kRingTimeout target:self selector:@selector(hangupClick) userInfo:nil repeats:NO];
    }
    
    return _ringTimer;
}

- (void)releaseRingTimer {
    if ([_ringTimer isValid]) {
        [_ringTimer invalidate];
        _ringTimer = nil;
    }
}

#pragma mark - Connect and Preview Timer
- (NSTimer *)connectAndPreviewTimer {
    if (_connectAndPreviewTimer == nil) {
        _connectAndPreviewTimer = [NSTimer scheduledTimerWithTimeInterval:kConnectAndPreviewTimeout target:self selector:@selector(connectAndPreviewTimeoutHandler) userInfo:nil repeats:NO];
    }
    
    _connectAndPreviewTimeout = NO;
    _connectTimes = 0;
    
    return _connectAndPreviewTimer;
}

- (void)releaseConectAndPreview {
    if ([_connectAndPreviewTimer isValid]) {
        [_connectAndPreviewTimer invalidate];
        _connectAndPreviewTimer = nil;
        _connectAndPreviewTimeout = NO;
        _connectTimes = 0;
    }
}

- (void)connectAndPreviewTimeoutHandler {
    _connectAndPreviewTimeout = YES;
    SHLogInfo(SHLogTagAPP, @"Connect and preview timeout, timeout time: %f", kConnectAndPreviewTimeout);
}

#pragma mark - Connect and Preview Handle
- (void)connectAndPreviewHandler {
    [self connectAndPreviewTimer];
    
    if (!_shCameraObj.isConnect) {
        NSString *message = NSLocalizedString(@"kConnecting", @"");
        [self.progressHUDPreview showProgressHUDWithMessage:message];
        
        WEAK_SELF(self);
        dispatch_async(self.previewQueue, ^{
            STRONG_SELF(self);
            
            [self connectCameraHandler];
        });
    } else {
        [self initPlayer];
        
        [self startPreview];
    }
}

- (void)connectCameraHandler {
    int retValue = [_shCameraObj connectCamera];
    SHLogInfo(SHLogTagAPP, @"Current connect times: %lu, is success: %d.", (unsigned long)++_connectTimes, retValue);
    
    if (self.alreadyBack) {
        SHLogInfo(SHLogTagAPP, @"Already exit preview, don't start stream.");
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUDPreview hideProgressHUD:YES];
        });
        
        return;
    }
    
    if (retValue != ICH_SUCCEED) {
        if (_connectAndPreviewTimeout) {
            [self connectFiledHandler:retValue];
        } else {
            if (retValue == ICH_TUTK_DEVICE_OFFLINE) {
                [self connectFiledHandler:retValue];
            } else {
                NSTimeInterval interval = kConnectAndPreviewCommonSleepTime;
                if (retValue == ICH_TUTK_IOTC_ER_DEVICE_EXCEED_MAX_SESSION) {
                    interval = kConnectAndPreviewSpecialSleepTime;
                }
                
                [self reConnectWithSleepForTimeInterval:interval];
            }
        }
    } else {
        [self connectSuccessHandler];
    }
}

- (void)reConnectWithSleepForTimeInterval:(NSTimeInterval)interval {
    SHLogInfo(SHLogTagAPP, @"Reconnect start, sleep time interval: %f.", interval);
    
    [_shCameraObj.sdk disableTutk];
    
    WEAK_SELF(self);
    [_shCameraObj disConnectWithSuccessBlock:^{
        STRONG_SELF(self);
        if (self.alreadyBack) {
            SHLogInfo(SHLogTagAPP, @"Already exit preview, don't reconnect.");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUDPreview hideProgressHUD:YES];
            });
            
            return;
        }
        
        [NSThread sleepForTimeInterval:interval];
        [self connectCameraHandler];
    } failedBlock:^{
        SHLogError(SHLogTagAPP, @"disconnect failed.");
    }];
}

- (void)connectSuccessHandler {
    if (_shCameraObj.isConnect) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initPlayer];
            [self updateTitle];
            
            [self startPreview];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUDPreview hideProgressHUD:YES];
            
            if (_shCameraObj == nil ||
                _shCameraObj.camera == nil ||
                _shCameraObj.camera.cameraUid == nil) {
                [self showConnectFailedAlertView];
            }
        });
    }
}

- (void)connectFiledHandler:(int)retValue {
    [self updatePreviewFailedGUI];
    
    NSString *name = _shCameraObj.camera.cameraName;
    NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
    NSString *errorInfo = @"";
    errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
    errorInfo = [errorInfo stringByAppendingString:NSLocalizedString(@"kExitPreview", nil)];
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUDPreview hideProgressHUD:YES];
            [weakself enableUserInteraction:NO];
        });
    }]];
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUDPreview hideProgressHUD:YES];
            [weakself goHome];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertC animated:YES completion:nil];
    });
}

- (void)updatePreviewFailedGUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        _pvFailedLabel.hidden = NO;
        _pvFailedLabel.text = NSLocalizedString(@"StartPVFailed", nil);
    });
}

- (void)addDeviceObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
}

#pragma mark - Resolution Handle
- (void)setupResolutionButton {
    _resolutionButton.array = [[SHCamStaticData instance] streamQualityArray];
    _resolutionButton.delegate = self;
    _resolutionButton.fontSize = 15.0;
}

- (void)updateResolutionButton:(ICatchVideoQuality)quality {
    _resolutionButton.row = quality;
    _resolutionButton.title = [[SHCamStaticData instance] streamQualityArray][quality];
}

- (void)didSelectOptionInHWOptionButton:(HWOptionButton *)optionButton {
    NSInteger index = optionButton.row;
    SHLogInfo(SHLogTagAPP, @"Current select row: %ld", (long)index);
    
    ICatchVideoQuality quality = (ICatchVideoQuality)index;
    if (quality == _shCameraObj.streamQuality) {
        SHLogInfo(SHLogTagAPP, @"Current quality already exist.");
        return;
    }
    
    [self.progressHUD showProgressHUDWithMessage:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_TARGET_QUEUE_DEFAULT, 0), ^{
        BOOL success = [_shCameraObj.sdk setVideoQuality:quality];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                _shCameraObj.streamQuality = quality;
                [self.progressHUD hideProgressHUD:YES];
            } else {
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kChangeStreamQualityFailed", nil) showTime:2.0];
            }
        });
    });
}

@end
