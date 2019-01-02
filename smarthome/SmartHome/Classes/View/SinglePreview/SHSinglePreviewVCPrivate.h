//
//  ViewControllerPrivate.h
//  SmartHome
//
//  Created by ZJ on 2017/4/20.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSinglePreviewVC.h"
#import "H264Decoder.h"
#import "HYOpenALHelper.h"
#import "PCMDataPlayer.h"

@interface SHSinglePreviewVC ()

@property (weak, nonatomic) IBOutlet UIImageView *preview;
@property (weak, nonatomic) IBOutlet UIButton *talkbackButton;
@property (weak, nonatomic) IBOutlet UIButton *muteButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;
@property (weak, nonatomic) IBOutlet UILabel *cameraNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *curTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoRecordTimerLabel;
@property (weak, nonatomic) IBOutlet UIView *footerView;

@property (weak, nonatomic) IBOutlet UILabel *videoCacheLabel;
@property (weak, nonatomic) IBOutlet UILabel *audioCacheLabel;
@property (weak, nonatomic) IBOutlet UIButton *returnButton;
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (weak, nonatomic) IBOutlet UIImageView *wifiStatusImgView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImgView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;

@property (weak, nonatomic) IBOutlet UIButton *resolutionButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *resolutionBtnWidthCons;
@property (weak, nonatomic) IBOutlet UILabel *bitRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (nonatomic) SHObserver *bitRateObserver;
@property (weak, nonatomic) IBOutlet UILabel *pvFailedLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *muteBtnWidthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *talkbackBtnWidthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captureBtnWidthCons;

@property (nonatomic) SystemSoundID stillCaptureSound;
@property (nonatomic) SystemSoundID delayCaptureSound;
@property (nonatomic) SystemSoundID changeModeSound;
@property (nonatomic) SystemSoundID videoCaptureSound;
@property (nonatomic) SystemSoundID burstCaptureSound;
@property (nonatomic) MBProgressHUD *progressHUD;
@property (nonatomic, getter = isVideoReCordStartOn) BOOL videoReCordStartOn;

@property (nonatomic, weak) AVSampleBufferDisplayLayer *avslayer;

@property (nonatomic, getter = isTalkBackRun) BOOL TalkBackRun;

@property (nonatomic) SHControlCenter *ctrl;
@property (nonatomic) SHCameraObject *shCameraObj;

@property (nonatomic) SHObserver *videoCacheObserver;
@property (nonatomic) SHObserver *audioCacheObserver;

@property(nonatomic) UIImage *startOnImage;
@property(nonatomic) UIImage *startOffImage;

@end
