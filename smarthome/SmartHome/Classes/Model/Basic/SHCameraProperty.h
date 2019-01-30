//
//  SHCamCamera.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class SHFileTable;
@class SHICatchEvent;

//typedef NS_OPTIONS(NSUInteger, SHPreviewMode) {
//    SHPreviewModeCameraOff = 1<<0,
//    SHPreviewModeCameraOn = 1<<1,
//    SHPreviewModeVideoOff = 1<<2,
//    SHPreviewModeVideoOn = 1<<3,
//    SHPreviewModeTalkBackOff = 1<<4,
//    SHPreviewModeTalkBackOn = 1<<5,
//};


typedef NS_OPTIONS(NSUInteger, SHPreviewMode) {
	SHPreviewModeCaptureOnFlag = 1,
	SHPreviewModeVideoOnFlag = 1<<1,
	SHPreviewModeTalkBackOnFlag = 1<<2,
};

@interface SHCameraProperty : NSObject

@property (nonatomic) SHPreviewMode previewMode;
//@property (nonatomic, assign) int curWhiteBalance;
//@property (nonatomic, assign) int curLightFrequency;
//@property (nonatomic, copy) NSString *curVideoSize;

@property (nonatomic) SHSettingData *whiteBalanceData;
@property (nonatomic) SHSettingData *lightFrequencyData;
@property (nonatomic) SHSettingData *videoSizeData;

@property (nonatomic) SHSettingData *pirData;
@property (nonatomic) SHSettingData *cameraBrightnessData;
@property (nonatomic) SHSettingData *vidRecDurationData;
@property (nonatomic) SHSettingData *micVolumeData;
@property (nonatomic) SHSettingData *speakerVolumeData;
@property (nonatomic) SHSettingData *sleepTimeData;

@property (nonatomic) SHSettingData *memorySizeData;
@property (nonatomic) SHSettingData *recStatusData;
@property (nonatomic) SHSettingData *pushMsgStatusData;
@property (nonatomic) SHSettingData *fasterConnectionData;
@property (nonatomic) SHSettingData *tamperalarmData;

@property (nonatomic) SHSettingData *aboutData;
@property (nonatomic) SHSettingData *timeZoneData;

@property (nonatomic, getter=isMute) BOOL mute;
@property (nonatomic, assign) int downloadSuccessedNum;
@property (nonatomic, assign) int downloadFailedNum;
@property (nonatomic, assign) int cancelDownloadNum;
//@property (nonatomic, strong) NSMutableArray *downloadArray;

@property (nonatomic) BOOL fwUpdate;
@property (nonatomic) BOOL serverOpened;
@property (nonatomic) double curAudioPts;
@property (nonatomic, getter=isTalk) BOOL talk;

@property (nonatomic) AVSampleBufferDisplayLayer *avslayer;
@property (nonatomic) CGRect avslayerFrame;
@property (nonatomic) SHPropertyQueryResult *sdCardResult;

@property (nonatomic) ICatchVideoFormat *videoFormat;
@property (nonatomic) ICatchAudioFormat *audioFormat;

@property (nonatomic) SHICatchEvent *curBatteryLevel;
@property (nonatomic, assign) int SDUseableSize;
@property (nonatomic, strong) SHICatchEvent *curChargeStatus;

- (void)cleanCurrentCameraAllProperty;
- (BOOL)checkSupportPropertyExist;
- (void)updateSDCardInfo:(SHCameraObject *)shCamObj;
- (void)cleanCacheFormat;
- (void)cleanCacheData;

@end
