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
#import "ICVoiceHud.h"
#import "RTCView.h"
#import "RTCButton.h"
#import "SHWaterView.h"
#import "CustomIOS7AlertView.h"
#import "AppDelegate.h"
#import "XDSDropDownMenu.h"

typedef enum : NSUInteger {
    CacheTypeVideo,
    CacheTypeAudio,
} CacheType;

static const CGFloat kMuteBtnDefaultWidth = 60;
static const CGFloat kTalkbackBtnDefaultWidth = 80;

@interface SHSinglePreviewVC () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, XDSDropDownMenuDelegate>

@property(nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property(nonatomic, retain) GCDiscreetNotificationView *bufferNotificationView;
@property (nonatomic) NSDate * currentDate;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) ICVoiceHud *voiceHud;

@property (nonatomic, strong) AVAudioPlayer *player;
@property (nonatomic,getter=isConnected) BOOL connected;
@property (nonatomic) BOOL disconnectHandling;
@property (nonatomic) BOOL noHidden;
@property (nonatomic, strong) NSTimer *talkAnimTimer;
@property (nonatomic) BOOL poweroffHandling;
@property (nonatomic, weak) UINavigationController *rootViewController;

@property (nonatomic, getter = isBatteryLowAlertShowed) BOOL batteryLowAlertShowed;
@property (nonatomic, strong) XDSDropDownMenu *resolutionMenu;

@end

@implementation SHSinglePreviewVC

#pragma mark - Init Variable
- (void)initParameter {
    _shCameraObj = [[SHCameraManager sharedCameraManger] getSHCameraObjectWithCameraUid:_cameraUid];
    self.ctrl = _shCameraObj.controler;
}

#pragma mark - Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self initParameter];
    
    [self initPreviewGUI];
    [self constructPreviewData];
    
    [self setupTalkButtonTarget];
    
    [self addGestureRecognizers];
}

- (void)addGestureRecognizers {
    //单指单击
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showController)];
    [self.view addGestureRecognizer:tap];
    tap.delegate = self;
}

- (void)setupTalkButtonTarget {
    [_talkbackButton addTarget:self action:@selector(talkButtonDragInside:) forControlEvents:UIControlEventTouchDragInside];
    if(_shCameraObj.cameraProperty.talk ) {
        _TalkBackRun = _shCameraObj.cameraProperty.talk;
        [self talkAnimTimer];
        _noHidden = YES;
    }
}

- (void)connectCamera {
    int retValue = [_shCameraObj connectCamera];
    
    if(retValue != ICH_SUCCEED) {
        NSString *name = _shCameraObj.camera.cameraName;
        NSString *errorMessage = [[[SHCamStaticData instance] tutkErrorDict] objectForKey:@(retValue)];
        NSString *errorInfo = @"";
        errorInfo = [errorInfo stringByAppendingFormat:@"[%@] %@",name,errorMessage];
        
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Warning",nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
        
        WEAK_SELF(self);
        [alertVC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            STRONG_SELF(self);
            [self goHome:nil];
        }]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self presentViewController:alertVC animated:YES completion:nil];
        });
    } else {

    }
}

- (void)initPlayer {
    [self setupSampleBufferDisplayLayer];

#if DataDisplayImmediately
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:^(BOOL isBuffering, BOOL timeout) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.preview && isBuffering) {
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateResolutionButton:_shCameraObj.streamQuality];

    if (!_shCameraObj.isConnect) {
        [self.progressHUD showProgressHUDWithMessage:nil];
        dispatch_async(dispatch_queue_create("SimglePreviewQueue", DISPATCH_QUEUE_SERIAL), ^{
            [self connectCamera];
            
            if (_shCameraObj.isConnect) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [self initPlayer];
                });
                [self startPreview];
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
        
        if (!_shCameraObj.streamOper.PVRun) {
            [self startPreview];
        } else {
            [self initCameraPropertyGUI];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(singleDownloadCompleteHandle:) name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraDisconnectHandle:) name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cameraPowerOffHandle:) name:kCameraPowerOffNotification object:nil];
    
    [self.preview addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
    
    self.talkbackButton.enabled = _shCameraObj.cameraProperty.serverOpened;
    [self.shCameraObj.cameraProperty addObserver:self forKeyPath:@"serverOpened" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)showConnectFailedAlertView {
    NSString *name = _shCameraObj.camera.cameraName;
    NSString *errorMessage = NSLocalizedString(@"kConnectionUnknownError", nil);
    NSString *errorInfo = [NSString stringWithFormat:@"[%@] %@", name ? name : @"", errorMessage];
    
    UIAlertController *alertC = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Tips", nil) message:errorInfo preferredStyle:UIAlertControllerStyleAlert];
    
    WEAK_SELF(self);
    [alertC addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Sure", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakself goHome:nil];
        });
    }]];
    
    [self presentViewController:alertC animated:YES completion:nil];
}

- (void)singleDownloadCompleteHandle:(NSNotification *)nc {
    NSDictionary *tempDict = nc.userInfo;
    
    NSString *msg = [SHTool createDownloadComplete:tempDict];
    
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
}

- (void)startPreview {
    [self initCameraPropertyGUI];

    [_shCameraObj.streamOper startMediaStreamWithEnableAudio:YES file:nil successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD hideProgressHUD:YES];
            [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
//            [self initCameraPropertyGUI];
            
            [self enableUserInteraction:YES];
        });

        [_shCameraObj initCamera];
    } failedBlock:^(NSInteger errorCode) {
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
        
    } target:nil streamCloseCallback:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self releaseTalkAnimTimer];
    
    if (_managedObjectContext) {
        if (_shCameraObj.streamOper.PVRun) {
            [_shCameraObj.streamOper stopMediaStreamWithComplete:nil];
        }
    }
    
    [super viewWillDisappear:animated];
    
    [_shCameraObj.streamOper initAVSLayer:self.avslayer bufferingBlock:nil];
    [self.avslayer removeFromSuperlayer];
    
    _notification = nil;
    
    if (_rootViewController) {
        [self restoreRootViewController:_rootViewController];
    }
    
    [self hideResolutionMenu];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kSingleDownloadCompleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCameraDisconnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.preview  removeObserver:self forKeyPath:@"bounds"];
    
    [self removePreviewCacheObserver];
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
    AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
    app.isFullScreenPV = NO;
        
    if (_managedObjectContext) {
        [self.progressHUD showProgressHUDWithMessage:nil];
        NSString *msgType = [NSString stringWithFormat:@"%@", _notification[@"msgType"]];
        if ([msgType isEqualToString:@"201"]) {
            if (_shCameraObj.controler.actCtrl.isRecord) {
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
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            SHLogInfo(SHLogTagAPP, @"QUIT -- FullScreen");
        }];
    }
}

#pragma mark - Init Preview GUI
- (void)setupSampleBufferDisplayLayer {
    AVSampleBufferDisplayLayer *avslayer = _shCameraObj.cameraProperty.avslayer;
    if (avslayer == nil) {
        avslayer = [[AVSampleBufferDisplayLayer alloc] init];
    }

    avslayer.bounds = _preview.bounds;
    avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
    avslayer.videoGravity = AVLayerVideoGravityResizeAspect;
    avslayer.backgroundColor = [[UIColor clearColor] CGColor];

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

    [self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
    
    _headerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    _footerView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"full scree-top"]];
    [_footerView setCornerWithRadius:5.0];
    
    _muteBtnWidthCons.constant = kMuteBtnDefaultWidth * kScreenWidthScale;
    _talkbackBtnWidthCons.constant = kTalkbackBtnDefaultWidth * kScreenWidthScale;
    _captureBtnWidthCons.constant = kMuteBtnDefaultWidth * kScreenWidthScale;
    
    _preview.image = [_shCameraObj.streamOper getLastFrameImage];
    _bitRateLabel.text = @"0kb/s";
    
    [self setupResolutionButton];
    [self setupZoomScrollView];
}

- (void)setButtonRadius:(UIButton *)button withRadius:(CGFloat)radius {
    button.layer.cornerRadius = radius;
    button.layer.masksToBounds = YES;
}

- (void)constructPreviewData {
    NSString *stillCaptureSoundUri = [[NSBundle mainBundle] pathForResource:@"Capture_Shutter" ofType:@"WAV"];
    id url = [NSURL fileURLWithPath:stillCaptureSoundUri];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_stillCaptureSound);
}

- (void)deconstructPreviewData {
    AudioServicesDisposeSystemSoundID(_stillCaptureSound);
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
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];
    } else {
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
                [self talkAnimTimer];
            }
            
            _shCameraObj.cameraProperty.talk = YES;
            _noHidden = YES;
        });
    } failedBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"kStartTalkBackFailed", @"") showTime:2.0];
			[self updatePreviewSceneByMode:_shCameraObj.cameraProperty.previewMode];
            
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
    
    [_shCameraObj.streamOper isMute:sender.tag successBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (sender.tag == 0) {
                sender.tag = 1;
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];

            } else {
                sender.tag = 0;
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute_1"] forState:UIControlStateNormal];
                [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
            }
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
}

- (void)setMuteButtonBackgroundImage {
    _muteButton.tag = _shCameraObj.cameraProperty.isMute;
    if (_muteButton.tag) {
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre"] forState:UIControlStateHighlighted];
    } else {
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute_1"] forState:UIControlStateNormal];
        [_muteButton setImage:[UIImage imageNamed:@"full screen video-btn-mute-pre_1"] forState:UIControlStateHighlighted];
    }
}

- (void)setToVideoOffScene {
    [self.talkbackButton setEnabled:YES];
    [self.captureButton setEnabled:YES];
    [self.muteButton setEnabled:YES];
    
    self.videoRecordTimerLabel.hidden = YES;
    
    [self setMuteButtonBackgroundImage];
}

- (void)setToVideoOnScene
{
    [self setToVideoOffScene];
	
    if (self.videoRecordTimerLabel.isHidden) {
        self.videoRecordTimerLabel.hidden = NO;
    }
}

- (void)setToTalkBackOffScene {
    
}

- (void)setToTalkBackOnScene {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
            if (_shCameraObj.cameraProperty.isMute) {
            } else {
            }
        } else {
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bounds"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            
            if (([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeLeft) || ([[UIApplication sharedApplication] statusBarOrientation] == UIInterfaceOrientationLandscapeRight)) {
                self.avslayer.bounds = self.view.bounds;
                self.avslayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
                
            } else {
                self.avslayer.bounds = _preview.bounds;
                self.avslayer.position = CGPointMake(CGRectGetMidX(_preview.bounds), CGRectGetMidY(_preview.bounds));
                
            }
            
            [self updateZoomViewLayout];

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
        _footerView.hidden = NO;
        _muteButton.hidden = NO;
    } else {
        if (self.headerView.isHidden) {
            self.headerView.hidden = NO;
            self.talkbackButton.hidden = NO;
            self.captureButton.hidden = NO;
            _footerView.hidden = NO;
            _muteButton.hidden = NO;
        } else {
            self.headerView.hidden = YES;
            self.talkbackButton.hidden = YES;
            self.captureButton.hidden = YES;
            _footerView.hidden = YES;
            _muteButton.hidden = YES;
            
            [self hideResolutionMenu];
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
    waterView.strokeColor = [UIColor ic_colorWithHex:kThemeColor]; //[UIColor colorWithRed:51/255.0 green:204/255.0 blue:204/255.0 alpha:1.0];
    waterView.radius = _talkbackButton.bounds.size.width * 0.5;
    
    waterView.backgroundColor = [UIColor clearColor];
    
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 若为UITableViewCellContentView（即点击了tableViewCell），则不截获Touch事件
    if ([NSStringFromClass([touch.view class]) isEqualToString:@"UITableViewCellContentView"]) {
        return NO;
    }
    
    return YES;
}

#pragma mark - Property
- (void)initCameraPropertyGUI {
//    [self initBatteryLevelIcon];
    [self initBatteryHandler];
    
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
                
            default:
                break;
        }
    }];
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
        self.batteryImgView.image = [UIImage imageNamed:@"vedieo-buttery_c"];
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
        self.batteryImgView.image = [UIImage imageNamed:@"vedieo-buttery_10"];
    });
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
        self.batteryImgView.image = batteryStatusImage;
        _batteryLabel.text = [NSString stringWithFormat:@"%d%%", level];

        if ([imageName isEqualToString:@"vedieo-buttery"] && !_batteryLowAlertShowed) {
            self.batteryLowAlertShowed = YES;
            [self.progressHUD showProgressHUDNotice:NSLocalizedString(@"ALERT_LOW_BATTERY", nil) showTime:2.0];
            
        } else if ([imageName isEqualToString:@"ic_battery_charging_green_24dp"]) {
            self.batteryLowAlertShowed = NO;
        }
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
        _bitRateLabel.text = [SHTool bitRateStringFromBits:value];
    });
}

- (void)enableUserInteraction:(BOOL)enable {
    _muteButton.enabled = enable;
    _talkbackButton.enabled = enable;
    _captureButton.enabled = enable;
    _pvFailedLabel.hidden = enable;
    _pvFailedLabel.text = enable ? nil : NSLocalizedString(@"StartPVFailed", nil);
}

#pragma mark - Resolution Handle
- (void)setupResolutionButton {
    [self setupResolutionButtonFrame];
    
    [_resolutionButton setCornerWithRadius:CGRectGetHeight(_resolutionButton.bounds) * 0.2 masksToBounds:NO];
    [_resolutionButton setBorderWidth:1.0 borderColor:[UIColor ic_colorWithHex:kThemeColor]];

    [self setupResolutionMenu];
}

- (void)setupResolutionMenu {
    self.resolutionMenu = [[XDSDropDownMenu alloc] init];
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
    
    CGFloat resolutionBtnWidth = width * 1.6;
    resolutionBtnWidth = resolutionBtnWidth > 85.0 ? resolutionBtnWidth : 85.0;
    SHLogInfo(SHLogTagAPP, @"String MAX width: %f, Resolution button width: %f", width, resolutionBtnWidth);
    
    _resolutionBtnWidthCons.constant = resolutionBtnWidth;
}

- (CGSize)stringSize:(NSString *)str font:(UIFont *)font {
    return [str boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:font} context:nil].size;
}

- (IBAction)changeResolutionClick:(id)sender {
    //调用方法判断是显示下拉菜单，还是隐藏下拉菜单
    [self setupDropDownMenu:self.resolutionMenu withTitleArray:[[SHCamStaticData instance] streamQualityArray] andButton:sender andDirection:@"up"];
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

- (void)updateResolutionButton:(ICatchVideoQuality)quality {
    _resolutionMenu.currentRow = quality;
    [_resolutionButton setTitle:[[SHCamStaticData instance] streamQualityArray][quality] forState:UIControlStateNormal];
}

#pragma mark - Setup Zoom GUI
- (void)setupZoomScrollView {
    [self setupZoomScrollViewFrame];
    [self.view insertSubview:self.zoomScrollView aboveSubview:self.preview];
    
    [self setupZooImageView];
    [self setupZoomButton];
}

- (void)setupZoomScrollViewFrame {
    CGRect rect = CGRectMake(0, 0, CGRectGetHeight(self.view.frame), CGRectGetWidth(self.view.frame));
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
    self.zoomScrollView.frame = self.preview.frame;
    self.zoomImageView.bounds = self.view.bounds;
    self.zoomImageView.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
    
    self.zoomScrollView.contentSize = self.zoomScrollView.frame.size;
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
    CGFloat x = CGRectGetHeight(self.view.bounds) - w - 4;
    CGFloat y = (CGRectGetHeight(self.zoomScrollView.bounds) - h ) * 0.5;
    CGRect rect = CGRectMake(x, y, w, h);
    
    self.zoomButton.frame = rect;
}

- (void)updateZoomButtonTitle {
    NSString *title = [NSString stringWithFormat:@"%.1fX", self.zoomScrollView.zoomScale];
    
    [self.zoomButton setTitle:title forState:UIControlStateNormal];
    [self.zoomButton setTitle:title forState:UIControlStateHighlighted];
}

#pragma mark - Zoom Handle
- (void)zoomButtonClick:(UIButton *)sender {
    [self tapZoomHandleWithCenter:self.preview.center];
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
    }
    
    return _zoomImageView;
}

@end
