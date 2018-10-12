// SHCameraPreviewVCPrivateHeader.h

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
 
 // Created by zj on 2018/3/22 下午1:33.
    

#import "SHCameraPreviewVC.h"
#import "CustomIOS7AlertView.h"

@interface SHCameraPreviewVC ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (weak, nonatomic) IBOutlet UIImageView *batteryImageView;
@property (weak, nonatomic) IBOutlet UIButton *funScreenButton;
@property (weak, nonatomic) IBOutlet UIButton *videoSizeButton;
@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIButton *speakerButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UILabel *curDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *pvFailedLabel;
@property (weak, nonatomic) IBOutlet UILabel *bitRateLabel;

@property (weak, nonatomic) IBOutlet UILabel *batteryLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *speakerTopCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *speakerLeftCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *speakerRightCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *audioBtnWidthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *speakerBtnWidthCons;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *captureBtnWidthCons;

@property (nonatomic, strong) AVSampleBufferDisplayLayer *avslayer;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, retain) GCDiscreetNotificationView *notificationView;
@property (nonatomic, retain) GCDiscreetNotificationView *bufferNotificationView;
@property (nonatomic, strong) dispatch_queue_t previewQueue;
@property (nonatomic, getter = isTalkBackRun) BOOL TalkBackRun;
@property (nonatomic, strong) NSTimer *talkAnimTimer;

@property (nonatomic) SystemSoundID stillCaptureSound;
//@property (nonatomic) SystemSoundID videoCaptureSound;

@property (nonatomic) SHControlCenter *ctrl;
@property (nonatomic) SHCameraObject *shCameraObj;

@property (nonatomic, strong) CustomIOS7AlertView *videoSizeView;

@end
