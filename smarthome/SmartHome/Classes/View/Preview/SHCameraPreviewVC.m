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
#import "SHDownloadManager.h"
#import "XDSDropDownMenu.h"
#import "SDWebImageManager.h"
#import "SHUpgradesInfo.h"
#import "SHDeviceUpgradeVC.h"

#define ENABLE_AUDIO_BITRATE 0

static NSString * const kPreviewStoryboardID = @"PreviewStoryboardID";
static const CGFloat kSpeakerTopConsDefaultValue = 50;
static const CGFloat kSpeakerTopConsDefaultValue_Special = 6;
static const CGFloat kSpeakerLeftConsDefaultValue = 40;
static const CGFloat kAudioBtnDefaultWidth = 60;
static const CGFloat kSpeakerBtnDefaultWidth = 80;
static const NSTimeInterval kRingTimeout = 50.0;
static const NSTimeInterval kConnectAndPreviewTimeout = 120.0;
static const NSTimeInterval kConnectAndPreviewCommonSleepTime = 1.0;

@interface SHCameraPreviewVC () <SH_XJ_SettingTVCDelegate, SHSinglePreviewVCDelegate, XDSDropDownMenuDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, assign) BOOL disconnectHandling;
@property (nonatomic, assign) BOOL poweroffHandling;
@property (nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;

@property (nonatomic, weak) RTCView *presentView;
@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic) SHObserver *bitRateObserver;

@property (nonatomic, strong) NSTimer *ringTimer;

@property (nonatomic, strong) NSTimer *connectAndPreviewTimer;
@property (nonatomic, assign) BOOL connectAndPreviewTimeout;
@property (nonatomic, assign) NSUInteger connectTimes;
@property (nonatomic, strong) MBProgressHUD *progressHUDPreview;
@property (nonatomic, assign) BOOL alreadyBack;
@property (nonatomic, strong) XDSDropDownMenu *resolutionMenu;
@property (nonatomic, weak) UIAlertController *upgradesAlertView;

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
    [self setupGUI];
    [self constructPreviewData];
}

- (void)viewWillAppear:(BOOL)animated {
    [SHTool setupCurrentFullScreen:NO];
    [super viewWillAppear:animated];
    [self updateTitle];

    [self setupCallView];
    [self updateResolutionButton:_shCameraObj.streamQuality];

    BOOL isRing = _managedObjectContext && ([[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"] || [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"202"]);
    if (!isRing) {
        [self connectAndPreview];
    }
    
    self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
    [self.shCameraObj.cameraProperty addObserver:self forKeyPath:@"serverOpened" options:NSKeyValueObservingOptionNew context:nil];
    [self updateTalkState];
    [self.previewImageView addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[NSUserDefaults standardUserDefaults] setObject:_notification forKey:kRecvNotification];

    [self releaseTalkAnimTimer];
    [self releaseConnectAndPreviewTimer];
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
    
    [self hideResolutionMenu];
    self.resolutionMenu = nil;
    
    [_shCameraObj.streamOper updatePreviewThumbnail];
    
    if (self.upgradesAlertView != nil) {
        [self.upgradesAlertView dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

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
    
    [self.zoomScrollView setZoomScale:kMinZoomScale animated:YES];
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
    
#if DataDisplayImmediately
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:^(BOOL isBuffering, BOOL timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.previewImageView && isBuffering) {
                [self.bufferNotificationView showGCDNoteWithMessage:NSLocalizedString(@"PREVIEW_BUFFERING_INFO", nil) andTime:1.0 withAcvity:NO];
            }
        });
    }];
#else
    [_shCameraObj.streamOper initDisplayImageView:self.zoomImageView bufferingBlock:^(BOOL isBuffering, BOOL timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.zoomImageView && isBuffering) {
                [self.bufferNotificationView showGCDNoteWithMessage:NSLocalizedString(@"PREVIEW_BUFFERING_INFO", nil) andTime:1.0 withAcvity:NO];
            }
        });
    }];
#endif
    [self setMuteButtonBackgroundImage];
}

- (void)connectCamera {
    int retValue = [_shCameraObj connectCamera];
    
    if (retValue != ICH_SUCCEED) {
        NSString *name = _shCameraObj.camera.cameraName;
        NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
        NSString *errorInfo = @"";
        errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
        errorInfo = [errorInfo stringByAppendingString:NSLocalizedString(@"kExitPreview", nil)];

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
                [weakself goHome];
            });
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertC animated:YES completion:nil];
        });
    } else {
    }
}

- (void)startMediaStream {
    [self.progressHUDPreview showProgressHUDWithMessage:NSLocalizedString(@"kStartStream", nil)];

    [_shCameraObj.streamOper startMediaStreamWithEnableAudio:YES file:nil successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            [self.progressHUDPreview hideProgressHUD:YES];
            [self isRing] ? [self talkBackAction:_speakerButton] : void();

            [self enableUserInteraction:YES];
        });
        
        [_shCameraObj initCamera];
        [self releaseConnectAndPreviewTimer];

        [self addDeviceObserver];
    } failedBlock:^(NSInteger errorCode) {
        [self reConnectWithSleepForTimeInterval:kConnectAndPreviewCommonSleepTime];
    } target:nil streamCloseCallback:nil];
}

- (void)startPreview {
    [self prepareCameraPropertyData];

    if (!_shCameraObj.streamOper.PVRun) {
        [self startMediaStream];
    } else {
        [self addDeviceObserver];
    }
}

- (void)prepareCameraPropertyData {
    if (_shCameraObj.isConnect) {
        [self initCameraPropertyGUI];
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
                        
                        [self startPreview];
                    });
                }
            });
        }
    }
}

- (void)checkLoginStatus {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
        if (!isSuccess) {
            [weakself loginPrompt];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginSuccess) name:kLoginSuccessNotification object:nil];
        }
    }];
}

- (void)loginPrompt {
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kAccountLoginExpired", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kLogin", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakself stopPlayRing];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserShouldLoginNotification object:nil];
    }]];
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)loginSuccess {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kLoginSuccessNotification object:nil];
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
    
    [self updateTalkButtonState];
}

- (void)setupGUI {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-back"] style:UIBarButtonItemStyleDone target:self action:@selector(returnBack)];
    self.navigationItem.rightBarButtonItem = _notification ? nil : [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-btn-setting"] style:UIBarButtonItemStyleDone target:self action:@selector(enterSettingAction)];
    
    _speakerTopCons.constant = (kScreenHeightScale == 1.0) ? kSpeakerTopConsDefaultValue_Special : kSpeakerTopConsDefaultValue * kScreenHeightScale;
    _speakerLeftCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _speakerRightCons.constant = kSpeakerLeftConsDefaultValue * kScreenWidthScale;
    _audioBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    _speakerBtnWidthCons.constant = kSpeakerBtnDefaultWidth * kScreenWidthScale;
    _captureBtnWidthCons.constant = kAudioBtnDefaultWidth * kScreenWidthScale;
    
    UIImage *img = _shCameraObj.camera.thumbnail;
    _previewImageView.image = img; //[img ic_imageWithSize:_previewImageView.bounds.size backColor:self.view.backgroundColor];
    _bitRateLabel.text = @"0kb/s"; //[NSString stringWithFormat:@"%dkb/s", 100 + (arc4random() % 100)];

    [self enableUserInteraction:NO];
    [self setupResolutionButton];
    [self addGestureRecognizers];
    [self setupZoomScrollView];
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
    avslayer.backgroundColor = [[UIColor clearColor] CGColor];
    
    CMTimebaseRef controlTimebase;
    CMTimebaseCreateWithMasterClock(CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase);
    avslayer.controlTimebase = controlTimebase;
    
    CMTimebaseSetRate(avslayer.controlTimebase, 1.0);
    
    self.avslayer = avslayer;
    
//    [self.previewImageView.layer addSublayer:self.avslayer];
    [self.zoomImageView.layer addSublayer:self.avslayer];
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
}

- (void)deconstructPreviewData {
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
}

#pragma mark - Property
- (void)initCameraPropertyGUI {
//    [self initBatteryLevelIcon];
    [self initBatteryHandler];
    [self checkDeviceUpgrades];
    
    SHICatchEvent *evt = _shCameraObj.cameraProperty.curBatteryLevel;
    evt ? [self updateBatteryLevelIcon:evt] : void();
    
    SHICatchEvent *statusEvt = _shCameraObj.cameraProperty.curChargeStatus;
    statusEvt ? [self updateChargeStatus:statusEvt] : void();
    
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
                
            case ICATCH_EVENT_VIDEO_BITRATE:
                [weakSelf updateBitRateLabel:evt.doubleValue1 + evt.doubleValue2];
                break;
                
            case ICATCH_EVENT_CHARGE_STATUS_CHANGED: {
                weakSelf.shCameraObj.cameraProperty.curChargeStatus = evt;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateChargeStatus:evt];
                });
            }
                break;
                
            case ICATCH_EVENT_UPGRADE_PACKAGE_DOWNLOADED_SIZE:
                if (self.shCameraObj.isConnect && self.shCameraObj.streamOper.PVRun) {
                    [weakSelf upgradeHandleWithHasBegun:YES];
                }
                break;
                
            case ICATCH_EVENT_NO_TALKING:
                [weakSelf noTalkingHandle:evt];
                break;
                
            case ICATCH_EVENT_CONNECTION_CLIENT_COUNT:
                [weakSelf updateTalkButtonState];
                break;
                
            default:
                break;
        }
    }];
}

- (void)updateTalkButtonState {
    NSString *speakerImg = @"video-btn-speak";
    NSString *speakerImg_Pre = @"video-btn-speak-pre";
    
    if (self.shCameraObj.cameraProperty.noTalking == 1) {
        speakerImg = @"video_btn_speak_1";
        speakerImg_Pre = @"video_btn_speak_pre_1";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.speakerButton setImage:[UIImage imageNamed:speakerImg] forState:UIControlStateNormal];
        [self.speakerButton setImage:[UIImage imageNamed:speakerImg_Pre] forState:UIControlStateHighlighted];
    });
}

- (void)noTalkingHandle:(SHICatchEvent *)evt {
    if (evt.intValue1 == 1) {
        _TalkBackRun ? [self showCannotTalkAlert] : void();
        [self stopCurrentTalkBack];
    }
    
    [self updateTalkButtonState];
}

- (void)initBatteryHandler {
    int batteryStatus = [_shCameraObj.controler.propCtrl prepareDataForChargeStatusWithCamera:_shCameraObj andCurResult:_shCameraObj.curResult];
    
    self.batteryLabel.hidden = (batteryStatus == 1);
    
    if (batteryStatus == 1) {
        [self setupChargeGUI];
        SHLogInfo(SHLogTagAPP, @"Device chargeing.");
    } else {
        [self initBatteryLevelIcon];
    }
}

- (void)setupChargeGUI {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.batteryImageView.image = [UIImage imageNamed:@"vedieo-buttery_c"];
    });
}

- (void)updateChargeStatus:(SHICatchEvent *)evt {
    int status = evt.intValue1;
    
    self.batteryLabel.hidden = (status == 1);
    
    if (status == 1) {
        [self setupChargeGUI];
    } else {
        [self updateBatteryLevelIcon:_shCameraObj.cameraProperty.curBatteryLevel];
    }
}

- (void)setupBatteryLevelDefaultIcon {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.batteryLabel.text = @"100%";
        self.batteryImageView.image = [UIImage imageNamed:@"vedieo-buttery_10"];
    });
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
    if (evt == nil) {
        SHLogWarn(SHLogTagAPP, @"evt is nil.");
        [self setupBatteryLevelDefaultIcon];
        return;
    }
    
    SHICatchEvent *statusEvt = _shCameraObj.cameraProperty.curChargeStatus;
    if (statusEvt && statusEvt.intValue1 == 1) {
        SHLogInfo(SHLogTagAPP, @"Device chargeing.");
        return;
    }
    
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
        SHLogInfo(SHLogTagAPP, @"before set, lastPreviewTime is : %@", self.shCameraObj.camera.pvTime);
        
        [self.shCameraObj updatePreviewThumbnailWithPvTime:pvTime];
        dispatch_async(dispatch_get_main_queue(),^(void){

            SHLogInfo(SHLogTagAPP, @"lastPreviewTime is : %@", self.shCameraObj.camera.pvTime);
        });
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
            SHLogError(SHLogTagAPP, @"因为系统原因, 无法访问麦克风");
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

- (void)showCannotTalkAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kOthersTalking", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (IBAction)talkBackAction:(id)sender {
    SHLogTRACE();
    
    if (self.shCameraObj.cameraProperty.noTalking == 1) {
        [self showCannotTalkAlert];
        return;
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
        if (_TalkBackRun /*&& interval > 1.0*/) {
            _TalkBackRun = NO;
            
            [self stopTalkBack];
            _noHidden = NO;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setMuteButtonBackgroundImage];
            });
        }
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
            
            if (![[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
                [self.progressHUD hideProgressHUD:YES];
                [self talkAnimTimer];
            }
            
            _shCameraObj.cameraProperty.talk = YES;
            _noHidden = YES;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStartTalkBackFailed", @"") showTime:2.0];
            
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
            [self.progressHUD hideProgressHUD:YES];
            
            _speakerButton.enabled = YES;
            _noHidden = NO;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            SHLogInfo(SHLogTagAPP, @"Failed to stop talkBack");
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
    
    [_shCameraObj.streamOper stillCaptureWithSuccessBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:/*@"Capture success"*/NSLocalizedString(@"kCaptureSuccess", nil) showTime:1.0];
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"STREAM_CAPTURE_FAILED", nil) showTime:1.5];
        });
    }];
}

- (IBAction)toggleAudioAction:(UIButton *)sender {
    SHLogTRACE();

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
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kAudioControl", @"") showTime:2.0];
        });
    }];
}

- (void)enterSettingAction {
    SHLogTRACE();
    
    if (self.shCameraObj.cameraProperty.clientCount > 1) {
        [self showCurrentOnlyCanPreviewAlert];
        
        SHLogWarn(SHLogTagAPP, @"Current only can preview, client count: %zd", self.shCameraObj.cameraProperty.clientCount);
        return;
    }
    
    UIViewController *vc = [self prepareSettingViewController];
    
    if (_shCameraObj.streamOper.PVRun) {
#if 0
        [self.progressHUD showProgressHUDWithMessage:nil];

        dispatch_async(/*self.previewQueue*/dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self stopCurrentTalkBack];
            
            [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.progressHUD hideProgressHUD:YES];
                    [self presentViewController:vc animated:YES completion:nil];
                });
            }];
        });
#else
        dispatch_async(self.previewQueue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:vc animated:YES completion:nil];
            });
            
            [self stopCurrentTalkBack];
            
            [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
            }];
        });
#endif
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];

            [self presentViewController:vc animated:YES completion:nil];
        });
    }
}

- (void)showCurrentOnlyCanPreviewAlert {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:NSLocalizedString(@"kCurrentOnlyCanPreview", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:nil]];
     
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (UIViewController *)prepareSettingViewController {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:kSettingStoryboardName bundle:nil];
    UINavigationController *navController = [sb instantiateViewControllerWithIdentifier:@"SettingStoryboardID"];
    SH_XJ_SettingTVC *vc = (SH_XJ_SettingTVC *)navController.topViewController;
    vc.cameraUid = _cameraUid;
    vc.delegate = self;
    [SHTool configureAppThemeWithController:navController];
    
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
    
    UINavigationController *nav = self.navigationController;
    SHLogInfo(SHLogTagAPP, @"==> nav : %@", nav);
    BOOL doNotDisconnect = /*_managedObjectContext &&*/ ![NSStringFromClass(nav.class) isEqualToString:@"SHMainViewController"];

    if (doNotDisconnect == NO && [self isDownloading]) {
        [self showDownloadingAlertView:doNotDisconnect];
    } else {
        [self returnBackHandle:doNotDisconnect];
    }
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

            if (doNotDisconnect == NO) {
                [self goHome];
            }
        });
        
        [self stopCurrentTalkBack];
        
        if (doNotDisconnect) {
            if (_shCameraObj.streamOper.PVRun) {
                [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
                    SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
                }];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
                
                [self goHome];
            });
            return;
        }
        
//        [_shCameraObj.streamOper stopPreview];
        [_shCameraObj.sdk disableTutk];
        [_shCameraObj.streamOper stopMediaStreamWithComplete:nil];
        [_shCameraObj disConnectWithSuccessBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD hideProgressHUD:YES];
                _progressHUD = nil;
            });
        } failedBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kDisconnectTimeout", @"") showTime:2.0];
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
            AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
            app.isFullScreenPV = YES;
            
            [self presentViewController:vc animated:YES completion:nil];
        });
    });
}

#pragma mark - DisconnectHandle
- (void)cameraDisconnectHandle:(NSNotification *)nc {
    if (_disconnectHandling) {
        SHLogInfo(SHLogTagAPP, @"Already do with disconnect event.");
        return;
    }
    
    SHLogTRACE();
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
        SHLogInfo(SHLogTagAPP, @"Already do with poweroff event.");
        return;
    }
    
    SHLogTRACE();
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
            
            [self returnBack];
        });
    }]];
    [alertVc addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"STREAM_RECONNECT", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf reconnect:shCamObj];
    }]];
    
    [self presentViewController:alertVc animated:YES completion:nil];
}

- (void)reconnect:(SHCameraObject *)shCamObj {
    SHLogTRACE();
    [self.progressHUDPreview showProgressHUDWithMessage:[NSString stringWithFormat:@"%@ %@...", shCamObj.camera.cameraName, NSLocalizedString(@"kReconnecting", @"")]];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        int retValue = [shCamObj connectCamera];
        if (retValue == ICH_SUCCEED) {
            
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
            
            [self returnBack];
        });
    }]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUDPreview hideProgressHUD:YES];
        [self presentViewController:alertVc animated:YES completion:nil];
    });
}

- (void)goHome {
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

#pragma mark - SHSinglePreviewVCDelegate
- (void)disconnectHandle {
    [self goHome];
}

#pragma mark - CallView
- (void)setupCallView {
    NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
    if (_managedObjectContext && ([msgType isEqualToString:@"201"] || [msgType isEqualToString:@"202"]) && _presentView == nil) {
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
    
    [self setupPresentViewNickName];
    [self setupPresentViewPortrait];
}

- (void)setupPresentViewNickName {
    NSString *nameString = _shCameraObj.camera.cameraName;
    
    if (_notification && [_notification.allKeys containsObject:@"name"]) {
        NSString *name = _notification[@"name"];
        if (name != nil && ![name isEqualToString:@""]) {
            nameString = [NSString stringWithFormat:NSLocalizedString(@"kDoorbellAnsweringDescription", nil), name, self.shCameraObj.camera.cameraName];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _presentView.nickName = nameString;
    });
}

- (void)setupPresentViewPortrait {
    if (_notification && [_notification.allKeys containsObject:@"attachment"]) {
        NSString *urlStr = _notification[@"attachment"];
        NSURL *url = [[NSURL alloc] initWithString:urlStr];
        
        if (url) {
            WEAK_SELF(self);
            [[SDWebImageDownloader sharedDownloader] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (image) {
                        weakself.presentView.portraitImageView.image = [weakself reDrawOrangeImage:image rangeRect:weakself.presentView.portraitImageView.bounds];
                    }
                });
            }];
        }
    }
}

- (UIImage *)reDrawOrangeImage:(UIImage *)image rangeRect:(CGRect)rect {
    NSLog(@"image size: %@", NSStringFromCGSize(image.size));
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextAddRect(ctx, rect);
    
    CGContextClip(ctx);
    
    [image drawInRect:rect];
    
    UIImage *drawImage =  UIGraphicsGetImageFromCurrentImageContext();
    NSLog(@"drawImage: %@", drawImage);
    
    UIGraphicsEndImageContext();
    
    return drawImage;
}

- (void)startPlayRing
{
    NSString *ringPath = [[NSBundle mainBundle] pathForResource:@"test.caf" ofType:nil];

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
    
    [self returnBack];
}

- (void)answerClick {
    [self stopPlayRing];
    
    [self closeCallView];

    [self connectAndPreview];
    
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
    _audioButton.enabled = enable;
    _speakerButton.enabled = enable;
    _captureButton.enabled = enable;
    self.navigationItem.rightBarButtonItem.enabled = enable;
    self.resolutionButton.enabled = enable;
}

- (void)connectAndPreview {
    [self connectAndPreviewHandler];
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
        NSString *bitRate = [SHTool bitRateStringFromBits:value];
        
        self.bitRateLabel.text = bitRate;
        self.bitRateInfoLabel.text = bitRate;
        
        self.clientCountLabel.text = [NSString stringWithFormat:@"%zd client", self.shCameraObj.cameraProperty.clientCount];
    });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    SHLogInfo(SHLogTagAPP, @"Observer keyPath: %@", keyPath);
    if ([keyPath isEqualToString:@"serverOpened"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.speakerButton.enabled = _shCameraObj.cameraProperty.serverOpened;
        });
    } else if ([keyPath isEqualToString:@"bounds"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            
            self.avslayer.bounds = _previewImageView.bounds;
            self.avslayer.position = CGPointMake(CGRectGetMidX(_previewImageView.bounds), CGRectGetMidY(_previewImageView.bounds));
            
            [self updateZoomViewLayout];
            
            [CATransaction commit];
        });
    }
}

- (BOOL)isRing {
    return _managedObjectContext && ([[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"201"] || [[NSString stringWithFormat:@"%@", _notification[@"msgType"]] isEqualToString:@"202"]);
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

- (void)releaseConnectAndPreviewTimer {
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
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initPlayer];
            
            [self startPreview];
        });
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
            if (retValue == ICH_TUTK_DEVICE_OFFLINE || retValue == ICH_TUTK_IOTC_ER_DEVICE_EXCEED_MAX_SESSION) {
                [self connectFiledHandler:retValue];
            } else {
                NSTimeInterval interval = kConnectAndPreviewCommonSleepTime;
//                if (retValue == ICH_TUTK_IOTC_ER_DEVICE_EXCEED_MAX_SESSION) {
//                    interval = kConnectAndPreviewSpecialSleepTime;
//                }
                
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
    }];
}

- (void)connectSuccessHandler {
    if (_shCameraObj.isConnect) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self initPlayer];
            [self updateTitle];
            [self updateTalkButtonState];

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
#if 0
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself.progressHUDPreview hideProgressHUD:YES];
            [weakself enableUserInteraction:NO];
        });
    }]];
#endif
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
    SHLogTRACE();
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
}

#pragma mark - Resolution Handle
- (void)setupResolutionButton {
    [self setupResolutionButtonFrame];
    
    [_resolutionButton setCornerWithRadius:CGRectGetHeight(_resolutionButton.bounds) * 0.2 masksToBounds:NO];
    [_resolutionButton setBorderWidth:1.0 borderColor:[UIColor ic_colorWithHex:kThemeColor]];
    [_resolutionButton setTitleColor:[UIColor ic_colorWithHex:kThemeColor] forState:UIControlStateNormal];
    
    [self setupResolutionMenu];
}

- (void)setupResolutionMenu {
    XDSDropDownMenu *resolutionMenu = [[XDSDropDownMenu alloc] init];
    self.resolutionMenu = resolutionMenu;
    self.resolutionMenu.tag = 1000;
    
    self.resolutionMenu.delegate = self;//设置代理
}

- (void)setupResolutionButtonFrame {
    NSArray *temp = [[SHCamStaticData instance] streamQualityArray];
    CGFloat width = 0;
    for (NSString *str in temp) {
        CGFloat w = [self stringSize:str font:_resolutionButton.titleLabel.font].width;
        width = MAX(width, w);
    }
    
    CGFloat resolutionBtnWidth = width + 32;
    resolutionBtnWidth = resolutionBtnWidth > 85.0 ? resolutionBtnWidth : 85.0;
    SHLogInfo(SHLogTagAPP, @"String MAX width: %f, Resolution button width: %f", width, resolutionBtnWidth);
    
    _resolutionBtnWidthCons.constant = resolutionBtnWidth;
}

- (CGSize)stringSize:(NSString *)str font:(UIFont *)font {
    return [str boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
}

- (void)updateResolutionButton:(ICatchVideoQuality)quality {
    _resolutionMenu.currentRow = quality;
    [_resolutionButton setTitle:[[SHCamStaticData instance] streamQualityArray][quality] forState:UIControlStateNormal];
}

- (void)setupDropDownMenu:(XDSDropDownMenu *)dropDownMenu withTitleArray:(NSArray *)titleArray andButton:(UIButton *)button andDirection:(NSString *)direction{
    
    CGRect btnFrame = [self getBtnFrame:button];
    
    if(dropDownMenu.tag == 1000){
        /*
         如果dropDownMenu的tag值为1000，表示dropDownMenu没有打开，则打开dropDownMenu
         */
        
        //初始化选择菜单
        [dropDownMenu showDropDownMenu:button withButtonFrame:btnFrame arrayOfTitle:titleArray arrayOfImage:nil animationDirection:direction];
        
        //添加到主视图上
        [self.view addSubview:dropDownMenu];
        
        //将dropDownMenu的tag值设为2000，表示已经打开了dropDownMenu
        dropDownMenu.tag = 2000;
    } else {
        /*
         如果dropDownMenu的tag值为2000，表示dropDownMenu已经打开，则隐藏dropDownMenu
         */
        [self hideResolutionMenu];
    }
}

- (CGRect)getBtnFrame:(UIButton *)button{
    return [button.superview convertRect:button.frame toView:self.view];
}

- (void)hideResolutionMenu {
    [self.resolutionMenu hideDropDownMenuWithBtnFrame:[self getBtnFrame:self.resolutionButton]];
    self.resolutionMenu.tag = 1000;
}

#pragma mark - 下拉菜单代理
/*
 在点击下拉菜单后，将其tag值重新设为1000
 */
- (void)setDropDownDelegate:(XDSDropDownMenu *)sender {
    sender.tag = 1000;
    
    [self changeResolutionWithRow:sender.currentRow];
}

- (void)changeResolutionWithRow:(NSInteger)row {
    SHLogInfo(SHLogTagAPP, @"Current select row: %ld", (long)row);
    
    ICatchVideoQuality quality = (ICatchVideoQuality)row;
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

- (IBAction)changeResolutionClick:(id)sender {
    [self setupDropDownMenu:self.resolutionMenu withTitleArray:[[SHCamStaticData instance] streamQualityArray] andButton:sender andDirection:@"up"];
}

#pragma mark - UITapGestureRecognizer
- (void)addGestureRecognizers {
    //单指单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleFingerTapHandler:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)singleFingerTapHandler:(UITapGestureRecognizer *)sender {
    if (self.resolutionMenu.tag == 1000) {
        return;
    }
    
    CGPoint point = [sender locationInView:sender.view];
    if (!CGRectContainsPoint(self.resolutionMenu.frame, point)) {
        [self hideResolutionMenu];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Setup Zoom GUI
- (void)setupZoomScrollView {
    [self setupZoomScrollViewFrame];
    [self.view addSubview:self.zoomScrollView];
    
    [self setupZooImageView];
    [self setupZoomButton];
}

- (void)setupZoomScrollViewFrame {
    CGRect rect = CGRectMake(0, CGRectGetHeight(self.headerView.bounds) + 50, CGRectGetWidth(_previewImageView.frame), CGRectGetHeight(_previewImageView.frame));
    self.zoomScrollView.frame = rect;
    
    self.zoomScrollView.contentSize = rect.size;
}

- (void)setupZooImageView {
    [self setupZoomImageViewFrame];
    
    [self setupImgae];
    
    [self.zoomScrollView addSubview:self.zoomImageView];
    
    [self zoomViewAddGestureRecognizer];
}

- (void)setupImgae {
    UIImage *image = self.shCameraObj.camera.thumbnail;
    
    self.zoomImageView.image = image;
}

- (void)setupZoomImageViewFrame {
    CGRect rect = CGRectMake(0, 0, CGRectGetWidth(_zoomScrollView.frame), CGRectGetHeight(_zoomScrollView.frame));
    self.zoomImageView.frame = rect;
}

- (void)zoomViewAddGestureRecognizer {
    // 双击缩放手势
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapHandle:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.zoomImageView addGestureRecognizer:doubleTap];
}

- (void)updateZoomViewLayout {
    self.zoomScrollView.frame = self.previewImageView.frame;
    [self setupZoomImageViewFrame];
    
    self.zoomScrollView.contentSize = self.zoomScrollView.frame.size;
    
    [self setupZoomButtonFrame];
}

- (void)setupZoomButton {
    [self setupZoomButtonFrame];
    [self.zoomButton setCornerWithRadius:CGRectGetWidth(self.zoomButton.bounds) * 0.5];

    [self.view addSubview:self.zoomButton];
    [self updateZoomButtonTitle];
}

- (void)setupZoomButtonFrame {
    CGFloat w = 40;
    CGFloat h = w;
    CGFloat x = CGRectGetWidth(self.view.bounds) - w - 4;
    CGFloat y = (CGRectGetHeight(self.zoomScrollView.bounds) - h ) * 0.5;
    CGRect rect = CGRectMake(x, y, w, h);
    rect = [self.zoomScrollView convertRect:rect toView:self.view];
    
    self.zoomButton.frame = rect;
}

- (void)updateZoomButtonTitle {
    NSString *title = [NSString stringWithFormat:@"%.1fX", self.zoomScrollView.zoomScale];
    
    [self.zoomButton setTitle:title forState:UIControlStateNormal];
    [self.zoomButton setTitle:title forState:UIControlStateHighlighted];
}

#pragma mark - Zoom Handle
- (void)zoomButtonClick:(UIButton *)sender {
    [self tapZoomHandleWithCenter:self.previewImageView.center];
}

- (void)doubleTapHandle:(UITapGestureRecognizer *)recognizer {
    CGPoint touchPoint = [recognizer locationInView:self.zoomImageView];
    
    [self tapZoomHandleWithCenter:touchPoint];
}

- (void)tapZoomHandleWithCenter:(CGPoint)point {
    if (self.zoomScrollView.zoomScale >= kMaxZoomScale) {
        [self.zoomScrollView setZoomScale:kMinZoomScale animated:YES];
        return;
    }
    
    CGFloat middleZoomScale = kMaxZoomScale * 0.5;
    CGFloat currentScale = self.zoomScrollView.zoomScale;
    CGFloat scale = self.zoomScrollView.maximumZoomScale;
    
    if (currentScale >= kMinZoomScale && currentScale < middleZoomScale) {
        scale = middleZoomScale;
    }
    
    CGRect newRect = [self getRectWithScale:scale andCenter:point];
    [self.zoomScrollView zoomToRect:newRect animated:YES];
}

/** 计算点击点所在区域frame */
- (CGRect)getRectWithScale:(CGFloat)scale andCenter:(CGPoint)center {
    CGRect newRect = CGRectZero;
    newRect.size.width =  self.zoomScrollView.frame.size.width/scale;
    newRect.size.height = self.zoomScrollView.frame.size.height/scale;
    newRect.origin.x = center.x - newRect.size.width * 0.5;
    newRect.origin.y = center.y - newRect.size.height * 0.5;
    
    return newRect;
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.zoomImageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self updateZoomButtonTitle];
}

#pragma mark - Zoom View Init
- (UIButton *)zoomButton {
    if (_zoomButton == nil) {
        _zoomButton = [[UIButton alloc] init];
        
        _zoomButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.25];
        _zoomButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_zoomButton addTarget:self action:@selector(zoomButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _zoomButton;
}

- (UIScrollView *)zoomScrollView {
    if (_zoomScrollView == nil) {
        _zoomScrollView = [[UIScrollView alloc] init];
        
        _zoomScrollView.showsHorizontalScrollIndicator = NO;
        _zoomScrollView.showsVerticalScrollIndicator = NO;
        _zoomScrollView.bounces = NO;
        _zoomScrollView.decelerationRate = UIScrollViewDecelerationRateFast;
        
        _zoomScrollView.minimumZoomScale = kMinZoomScale;
        _zoomScrollView.maximumZoomScale = kMaxZoomScale;
        _zoomScrollView.bouncesZoom = NO;
        
        _zoomScrollView.delegate = self;
    }
    
    return _zoomScrollView;
}

- (UIImageView *)zoomImageView {
    if (_zoomImageView == nil) {
        _zoomImageView = [[UIImageView alloc] init];
        
        _zoomImageView.userInteractionEnabled = YES;
        _zoomImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    
    return _zoomImageView;
}

- (void)checkDeviceUpgrades {
    [SHUpgradesInfo checkUpgradesWithCameraObj:_shCameraObj completion:^(BOOL hint, SHUpgradesInfo * _Nullable info) {

        if (![[SHTool appVisibleViewController] isMemberOfClass:[self class]]) {
            SHLogInfo(SHLogTagAPP, @"Current already not preview page.");
            return;
        }
        
        if (hint == YES) {
            if (self.shCameraObj.cameraProperty.clientCount > 1) {
                return;
            }
            [self showUpgradesAlertViewWithVersionInfo:info];
        }
    }];
}


- (void)showUpgradesAlertViewWithVersionInfo:(SHUpgradesInfo *)info {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertVC setValue:[SHUpgradesInfo upgradesAlertViewTitle] forKey:@"attributedTitle"];
    [alertVC setValue:[SHUpgradesInfo upgradesAlertViewMessageWithInfo:info] forKey:@"attributedMessage"];
    
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kLater", nil) style:UIAlertActionStyleDefault handler:nil]];
    [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"kRightAwayUpdate", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self upgradeHandleWithHasBegun:NO];
    }]];
    
    self.upgradesAlertView = alertVC;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self presentViewController:alertVC animated:YES completion:nil];
    });
}

- (void)upgradeHandleWithHasBegun:(BOOL)hasBegun {
    SHDeviceUpgradeVC *vc = [SHDeviceUpgradeVC deviceUpgradeVCWithCameraObj:self.shCameraObj];
    vc.hasBegun = hasBegun;
    
    dispatch_async(self.previewQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController pushViewController:vc animated:YES];
        });
        
        [self stopCurrentTalkBack];
        
        [_shCameraObj.streamOper stopMediaStreamWithComplete:^{
            SHLogInfo(SHLogTagAPP, @"stopMediaStream success.");
        }];
    });
}

@end
