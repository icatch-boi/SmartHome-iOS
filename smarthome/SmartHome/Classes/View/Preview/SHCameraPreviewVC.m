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

#define ENABLE_AUDIO_BITRATE 0

static NSString * const kPreviewStoryboardID = @"PreviewStoryboardID";
static const CGFloat kSpeakerTopConsDefaultValue = 50;
static const CGFloat kSpeakerTopConsDefaultValue_Special = 6;
static const CGFloat kSpeakerLeftConsDefaultValue = 40;
static const CGFloat kAudioBtnDefaultWidth = 60;
static const CGFloat kSpeakerBtnDefaultWidth = 80;

@interface SHCameraPreviewVC () <UITableViewDelegate, UITableViewDataSource, SH_XJ_SettingTVCDelegate, SHSinglePreviewVCDelegate>

@property (nonatomic, strong) SHSettingData *videoSizeData;
@property (nonatomic, assign) BOOL disconnectHandling;
@property (nonatomic, assign) BOOL poweroffHandling;
@property (nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;
@property (nonatomic, strong) NSTimer *currentDateTimer;

@property (nonatomic, strong) RTCView *presentView;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic) SHObserver *bitRateObserver;

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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTitle];
//    [self prepareVideoSizeData];
    [self setupCallView];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
    
//    [self currentDateTimer];
    self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
    [self.shCameraObj.cameraProperty addObserver:self forKeyPath:@"serverOpened" options:NSKeyValueObservingOptionNew context:nil];
    [self updateTalkState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
//    [self initCameraPropertyGUI];
//    [self checkLoginStatus];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
//    if (_TalkBackRun) {
//        [self talkBackAction:nil];
//    }
    [self releaseTalkAnimTimer];
    
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:nil];
    [self.avslayer removeFromSuperlayer];
    [self closeCallView];
    [self stopPlayRing];
    _notification = nil;
    _managedObjectContext = nil;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self removeVideoBitRateObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self releaseCurrentDateTimer];
    [self.shCameraObj.cameraProperty removeObserver:self forKeyPath:@"serverOpened"];
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
        errorInfo = [errorInfo stringByAppendingString:@"确定要退出Preview吗 ?"];
        
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
    [self.progressHUD showProgressHUDWithMessage:nil];

    [_shCameraObj.streamOper startMediaStreamWithEnableAudio:YES file:nil successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self isRing] ? (_shCameraObj.cameraProperty.serverOpened ? [self talkBackAction:_speakerButton] : void()) : [self.progressHUD hideProgressHUD:YES];
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

- (void)startPreview {
    if (!_shCameraObj.streamOper.PVRun) {
        [self startMediaStream];
    } else {
        [self addVideoBitRateObserver];
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
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:@"用户登录已过期，请重新登录." preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:@"登录" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-setting"] style:UIBarButtonItemStyleDone target:self action:@selector(enterSettingAction)];
    
    _speakerTopCons.constant = (kScreenHeightScale == 1.0) ? kSpeakerTopConsDefaultValue_Special : kSpeakerTopConsDefaultValue * kScreenHeightScale;
    _speakerLeftCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _speakerRightCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _audioBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    _speakerBtnWidthCons.constant = kSpeakerBtnDefaultWidth * kScreenWidthScale;
    _captureBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    
    UIImage *img = _shCameraObj.camera.thumbnail;
//    img = img ? img : [UIImage imageNamed:@"default_thumb"];
    _previewImageView.image = [img ic_imageWithSize:_previewImageView.bounds.size backColor:self.view.backgroundColor];
    _bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", 100 + (arc4random() % 100)];
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
}

- (void)updateBatteryLevelIcon:(SHICatchEvent *)evt {
    int level = evt.intValue1;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *imageName = [_shCameraObj.controler.propCtrl transBatteryLevel2NStr:level];
        UIImage *batteryStatusImage = [UIImage imageNamed:imageName];
        self.batteryImageView.image = batteryStatusImage;
        _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];

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
//            _noHidden = NO;
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
//            _noHidden = YES;
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
//            _noHidden = NO;
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
            [self.progressHUD showProgressHUDNotice:@"Capture success" showTime:1.0];
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
}

- (void)returnBack {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraDisconnectNotification object:nil];
    if (!_shCameraObj.isConnect) {
        [self goHome];
        return;
    }
    
    UINavigationController *nav = self.navigationController;
    NSLog(@"==> nav : %@", nav);
    BOOL doNotDisconnect = _managedObjectContext && ![NSStringFromClass(nav.class) isEqualToString:@"SHMainViewController"];
    
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
    dispatch_async(self.previewQueue, ^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"XJMain" bundle:nil];
        SHSinglePreviewVC *vc = [sb instantiateViewControllerWithIdentifier:@"SinglePreviewID"];
        vc.cameraUid = _shCameraObj.camera.cameraUid;
        vc.delegate = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:vc animated:YES completion:nil];
        });
    });
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
    [self.progressHUD showProgressHUDWithMessage:[NSString stringWithFormat:@"%@ %@...", shCamObj.camera.cameraName, NSLocalizedString(@"kReconnecting", @"")]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        int retValue = [shCamObj connectCamera];
        if (retValue == ICH_SUCCEED) {
//            [shCamObj initCamera];
            
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
            [self returnBack];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideProgressHUD:YES];
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
    waterView.strokeColor = [UIColor ic_colorWithHex:kButtonThemeColor]; //[UIColor colorWithRed:51/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
    waterView.radius = _speakerButton.bounds.size.width * 0.5;
    
    waterView.backgroundColor = [UIColor clearColor];
    
    //    [self.view addSubview:waterView];
    [self.view insertSubview:waterView belowSubview:_speakerButton];
    
    [UIView animateWithDuration:2 animations:^{
        
        waterView.transform = CGAffineTransformScale(waterView.transform, 2, 2);
        
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
        _presentView = [[RTCView alloc] initWithIsVideo:NO isCallee:YES inView:self.navigationController.view];

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
    
    if (_shCameraObj.isConnect) {
        [self startPreview];
    } else {
        [self connectAndPreview];
    }
    
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
    _pvFailedLabel.hidden = enable;
    _pvFailedLabel.text = enable ? nil : NSLocalizedString(@"StartPVFailed", nil);
}

- (void)connectAndPreview {
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
        _bitRateLabel.text = [NSString stringWithFormat:@"%dkb/s", (int)value];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"serverOpened"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
        });
        
//        if (_shCameraObj.cameraProperty.serverOpened) {
            BOOL isRing = _managedObjectContext && [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"];
            isRing ? [self talkBackAction:_speakerButton] : void();
//        }
    }
}

- (BOOL)isRing {
    return _managedObjectContext && [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"];
}

@end
