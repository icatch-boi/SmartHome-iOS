//
//  WifiCamStaticData.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "SHCamStaticData.h"


@implementation SHCamStaticData


+ (SHCamStaticData *)instance {
  static SHCamStaticData *instance = nil;
  /*
   @synchronized(self) {
   if(!instance) {
   instance = [[self alloc] init];
   }
   }
   */
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{ instance = [[self alloc] initSingleton]; });
  return instance;
}

- (id)init {
  // Forbid calls to –init or +new
  //NSAssert(NO, @"Cannot create instance of Singleton");
  
  // You can return nil or [self initSingleton] here,
  // depending on how you prefer to fail.
  return [self initSingleton];
}

// Real (private) init method
- (id)initSingleton {
  if (self = [super init]) {
    // Init code
    //_session = new ICatchWificamSession();
  }
  return self;
}


#pragma mark - Global static table
-(NSDictionary *)captureDelayDict
{
    return @{};/*@{@(CAP_DELAY_NO):@"Off",
                @(CAP_DELAY_2S):@"2s",
                @(5000):@"5s",
                @(CAP_DELAY_10S):@"10s"};*/
}

-(NSDictionary *)liveSizeDict
{
    return @{@"640x360" : @[@"H640x360",  @"640x360 H.264"],
             @"854x480" : @[@"H854x480",  @"854x480 H.264"],
             @"1280x720": @[@"H1280x720", @"1280x720 H.264"],
             };
}

-(NSDictionary *)videoSizeDict
{
    return @{
             @"3840x2160 60": @[@"4K60", @"3840x2160 60fps"],
             @"3840x2160 50": @[@"4K50", @"3840x2160 50fps"],
             @"3840x2160 30": @[@"4K30", @"3840x2160 30fps"],
             @"3840x2160 25": @[@"4K25", @"3840x2160 25fps"],
             @"3840x2160 24": @[@"4K24", @"3840x2160 24fps"],
             @"3840x2160 15": @[@"4K15", @"3840x2160 15fps"],
             @"3840x2160 10": @[@"4K10", @"3840x2160 10fps"],
             
             @"2704x1524 60": @[@"2.7K60", @"2704x1524 60fps"],
             @"2704x1524 50": @[@"2.7K50", @"2704x1524 50fps"],
             @"2704x1524 30": @[@"2.7K30", @"2704x1524 30fps"],
             @"2704x1524 25": @[@"2.7K25", @"2704x1524 25fps"],
             @"2704x1524 24": @[@"2.7K24", @"2704x1524 24fps"],
             @"2704x1524 15": @[@"2.7K15", @"2704x1524 15fps"],
             
             @"1920x1440 30":@[@"1440P30",@"1920x1440 30fps"],
             @"1920x1440 25":@[@"1440P25",@"1920x1440 25fps"],
             @"1920x1440 24":@[@"1440P24",@"1920x1440 24fps"],
             
             @"1920x1080 60 HQ":@[@"FHD60",@"1920x1080 60fps HQ"],
             @"1920x1080 50 HQ":@[@"FHD50",@"1920x1080 50fps HQ"],
             @"1920x1080 48 HQ":@[@"FHD48",@"1920x1080 48fps HQ"],
             @"1920x1080 30 HQ":@[@"FHD30",@"1920x1080 30fps HQ"],
             @"1920x1080 25 HQ":@[@"FHD25",@"1920x1080 25fps HQ"],
             @"1920x1080 24 HQ":@[@"FHD24",@"1920x1080 24fps HQ"],
             @"1920x1080 120 HQ":@[@"FHD120", @"1920x1080 120fps HQ"],
             
             @"1280x960 120 HQ":@[@"960P120",@"1280x960 120fps HQ"],
             @"1280x960 60 HQ": @[@"960P60",@"1280x960 60fps HQ"],
             @"1280x960 50 HQ": @[@"960P50",@"1280x960 50fps HQ"],
             @"1280x960 48 HQ": @[@"960P48",@"1280x960 48fps HQ"],
             @"1280x960 30 HQ": @[@"960P30",@"1280x960 30fps HQ"],
             @"1280x960 25 HQ": @[@"960P25",@"1280x960 25fps HQ"],
             @"1280x960 24 HQ": @[@"960P24",@"1280x960 24fps HQ"],

             @"1280x720 240 HQ":@[@"HD240",@"1280x720 240fps HQ"],
             @"1280x720 120 HQ":@[@"HD120",@"1280x720 120fps HQ"],
             @"1280x720 60 HQ":@[@"HD60",@"1280x720 60fps HQ"],
             @"1280x720 50 HQ":@[@"HD50",@"1280x720 50fps HQ"],
             @"1280x720 48 HQ":@[@"HD48",@"1280x720 48fps HQ"],
             @"1280x720 30 HQ":@[@"HD30",@"1280x720 30fps HQ"],
             @"1280x720 25 HQ":@[@"HD25",@"1280x720 25fps HQ"],
             @"1280x720 24 HQ":@[@"HD24",@"1280x720 24fps HQ"],
             
             @"848x480 240": @[@"WVGA240", @"848x480 240fps"],
             
             @"640x480 240 HQ":@[@"VGA240",@"640x480 240fps HQ"],
             @"640x480 120 HQ": @[@"VGA120", @"640x480 120fps HQ"],
             @"640x360 240": @[@"VGA240", @"640x360 240fps"],
             @"640x360 120": @[@"VGA120", @"640x360 120fps"],
             //add
             @"640x480 60 HQ": @[@"VGA60", @"640x480 60fps HQ"],
             @"640x480 50 HQ": @[@"VGA50", @"640x480 50fps HQ"],
             @"640x480 48 HQ": @[@"VGA48", @"640x480 48fps HQ"],
             @"640x480 30 HQ": @[@"VGA30", @"640x480 30fps HQ"],
             @"640x480 25 HQ": @[@"VGA25", @"640x480 25fps HQ"],
             @"640x480 24 HQ": @[@"VGA24", @"640x480 24fps HQ"],

             @"3840x1920 15": @[@"4K15", @"3840x1920 15fps"],
             @"3840x1920 30": @[@"4K30", @"3840x1920 30fps"],
             @"2800x1400 25": @[@"2.7K25", @"2800x1400 25fps"],
             @"2880x1440 25": @[@"2.7K25", @"2880x1440 25fps"],
             @"2880x1440 30": @[@"2.7K30", @"2880x1440 30fps"],
             @"2560x1280 30": @[@"1280P30", @"2560x1280 30fps"],
             @"2560x1280 60": @[@"1280P60", @"2560x1280 60fps"],
             @"1920x960 120 HQ" : @[@"960P120", @"1920x960 120fps HQ"],
             @"1920x960 60 HQ" : @[@"960P60", @"1920x960 60fps HQ"],
             @"1920x960 50 HQ" : @[@"960P50", @"1920x960 50fps HQ"],
             @"1920x960 48 HQ" : @[@"960P48", @"1920x960 48fps HQ"],
             @"1920x960 30 HQ" : @[@"960P30", @"1920x960 30fps HQ"],
             @"1920x960 25 HQ" : @[@"960P25", @"1920x960 25fps HQ"],
             @"1920x960 24 HQ" : @[@"960P24", @"1920x960 24fps HQ"],
             
             @"1440x960 30" : @[@"960P30", @"1440x960 30fps"],
             @"1280x720 15" : @[@"HD15", @"1280x720 15fps"],
             @"1280x640 15" : @[@"640P15", @"1280x640 15fps"],
             @"480x640 120" : @[@"640P120", @"480x640 120fps"],
             @"240x320 240" : @[@"320P240", @"240x320 240fps"],
             @"2048x1536 30": @[@"2K30", @"2048x1536 30fps"],
             
             @"320x240 240 HQ": @[@"240P240", @"320x240 240fps HQ"],
             @"320x240 120 HQ": @[@"240P120", @"320x240 120fps HQ"],
             @"320x240 60 HQ": @[@"240P60", @"320x240 60fps HQ"],
             @"320x240 50 HQ": @[@"240P50", @"320x240 50fps HQ"],
             @"320x240 48 HQ": @[@"240P48", @"320x240 48fps HQ"],
             @"320x240 30 HQ": @[@"240P30", @"320x240 30fps HQ"],
             @"320x240 25 HQ": @[@"240P25", @"320x240 25fps HQ"],
             @"320x240 24 HQ": @[@"240P24", @"320x240 24fps HQ"],

             @"1920x1080 60 LQ":@[@"FHD60",@"1920x1080 60fps LQ"],
             @"1920x1080 50 LQ":@[@"FHD50",@"1920x1080 50fps LQ"],
             @"1920x1080 48 LQ":@[@"FHD48",@"1920x1080 48fps LQ"],
             @"1920x1080 30 LQ":@[@"FHD30",@"1920x1080 30fps LQ"],
             @"1920x1080 25 LQ":@[@"FHD25",@"1920x1080 25fps LQ"],
             @"1920x1080 24 LQ":@[@"FHD24",@"1920x1080 24fps HQ"],
             @"1920x1080 120 LQ":@[@"FHD120", @"1920x1080 120fps HQ"],
             
             @"1920x960 120 LQ" : @[@"960P120", @"1920x960 120fps LQ"],
             @"1920x960 60 LQ" : @[@"960P60", @"1920x960 60fps LQ"],
             @"1920x960 50 LQ" : @[@"960P50", @"1920x960 50fps LQ"],
             @"1920x960 48 LQ" : @[@"960P48", @"1920x960 48fps LQ"],
             @"1920x960 30 LQ" : @[@"960P30", @"1920x960 30fps LQ"],
             @"1920x960 25 LQ" : @[@"960P25", @"1920x960 25fps LQ"],
             @"1920x960 24 LQ" : @[@"960P24", @"1920x960 24fps LQ"],
             
             @"1280x960 120 LQ":@[@"960P120",@"1280x960 120fps LQ"],
             @"1280x960 60 LQ": @[@"960P60",@"1280x960 60fps LQ"],
             @"1280x960 50 LQ": @[@"960P50",@"1280x960 50fps LQ"],
             @"1280x960 48 LQ": @[@"960P48",@"1280x960 48fps LQ"],
             @"1280x960 30 LQ": @[@"960P30",@"1280x960 30fps LQ"],
             @"1280x960 25 LQ": @[@"960P25",@"1280x960 25fps LQ"],
             @"1280x960 24 LQ": @[@"960P24",@"1280x960 24fps LQ"],
             
             @"1280x720 240 LQ":@[@"HD240",@"1280x720 240fps LQ"],
             @"1280x720 120 LQ":@[@"HD120",@"1280x720 120fps LQ"],
             @"1280x720 60 LQ":@[@"HD60",@"1280x720 60fps LQ"],
             @"1280x720 50 LQ":@[@"HD50",@"1280x720 50fps LQ"],
             @"1280x720 48 LQ":@[@"HD48",@"1280x720 48fps LQ"],
             @"1280x720 30 LQ":@[@"HD30",@"1280x720 30fps LQ"],
             @"1280x720 25 LQ":@[@"HD25",@"1280x720 25fps LQ"],
             @"1280x720 24 LQ":@[@"HD24",@"1280x720 24fps LQ"],
             
             @"640x480 240 LQ":@[@"VGA240",@"640x480 240fps HQ"],
             @"640x480 120 LQ": @[@"VGA120", @"640x480 120fps LQ"],
             @"640x480 60 LQ": @[@"VGA60", @"640x480 60fps LQ"],
             @"640x480 50 LQ": @[@"VGA50", @"640x480 50fps LQ"],
             @"640x480 48 LQ": @[@"VGA48", @"640x480 48fps LQ"],
             @"640x480 30 LQ": @[@"VGA30", @"640x480 30fps LQ"],
             @"640x480 25 LQ": @[@"VGA25", @"640x480 25fps LQ"],
             @"640x480 24 LQ": @[@"VGA24", @"640x480 24fps LQ"],

             @"320x240 240 LQ": @[@"240P240", @"320x240 240fps LQ"],
             @"320x240 120 LQ": @[@"240P120", @"320x240 120fps LQ"],
             @"320x240 60 LQ": @[@"240P60", @"320x240 60fps LQ"],
             @"320x240 50 LQ": @[@"240P50", @"320x240 50fps LQ"],
             @"320x240 48 LQ": @[@"240P48", @"320x240 48fps LQ"],
             @"320x240 30 LQ": @[@"240P30", @"320x240 30fps LQ"],
             @"320x240 25 LQ": @[@"240P25", @"320x240 25fps LQ"],
             @"320x240 24 LQ": @[@"240P24", @"320x240 24fps LQ"],
             };
}

-(NSDictionary *)imageSizeDict
{
    return @{
             @"5120x3840":@"20M",
             @"4608x3456":@"16M",
             @"4116x3312":@"14M",
             @"4000x3000":@"12M",
             @"3648x2736":@"10M",
             @"3456x2592":@"9M",
             @"3264x2448":@"8M",
             @"3640x2048":@"7M",
             @"2816x2112":@"6M",
             @"2560x1920":@"5M",
             @"2304x1728":@"4M",
             @"2048x1536":@"3M",
             @"1920x1080":@"2M",
             @"1280x960":@"1M",
             @"640x480":@"VGA",
             //add
             @"7744x3872":@"30M",
             @"7776x3888":@"30M",
             @"5660x2830":@"20M",
             @"5376x2688":@"14M",
             @"3888x1944":@"8M",
             @"3872x1936":@"7M",
             @"3027x1536":@"5M",
             @"3040x1520":@"5M",
             @"3008x1504":@"4M",
             @"2624x1312":@"3M",
             @"2048x1024":@"2M"
             
             };
}

-(NSDictionary *)awbDict
{
  return @{@(WB_AUTO):@"awb_auto",
           @(WB_CLOUDY):@"awb_cloudy",
           @(WB_DAYLIGHT):@"awb_daylight",
           @(WB_FLUORESCENT):@"awb_fluoresecent",
           @(WB_TUNGSTEN):@"awb_incadescent"};
}

-(NSDictionary *)burstNumberDict
{
    return @{};/*@{@(BRUST_NUMBER_HS):@(0),
                @(BURST_NUMBER_10):@(10),
                @(BURST_NUMBER_5):@(5),
                @(BURST_NUMBER_3):@(3)};*/
}

-(NSDictionary *)delayCaptureDict
{
    
    return @{};/*@{@(CAP_DELAY_NO):@(0),
                @(CAP_DELAY_2S):@(2),
                @(5000):@(5),
                @(CAP_DELAY_10S):@(10)};*/
}

-(NSDictionary *)whiteBalanceDict
{
  return @{@(WB_AUTO):NSLocalizedString(@"SETTING_AWB_AUTO", @""),
           @(WB_CLOUDY):NSLocalizedString(@"SETTING_AWB_CLOUDY", @""),
           @(WB_DAYLIGHT):NSLocalizedString(@"SETTING_AWB_DAYLIGHT", @""),
           @(WB_FLUORESCENT):NSLocalizedString(@"SETTING_AWB_FLUORESECENT", @""),
           @(WB_TUNGSTEN):NSLocalizedString(@"SETTING_AWB_INCANDESCENT", @"")};
}

-(NSDictionary *)burstNumberStringDict
{
    return @{};/*@{@(BRUST_NUMBER_HS):@[NSLocalizedString(@"SETTING_BURST_HIGHEST_SPEED", nil), @""],
                @(BURST_NUMBER_OFF):@[NSLocalizedString(@"SETTING_BURST_OFF", nil), @""],
                @(BURST_NUMBER_3):@[NSLocalizedString(@"SETTING_BURST_3_PHOTOS", nil), @"continuous_shot_1"],
                @(BURST_NUMBER_5):@[NSLocalizedString(@"SETTING_BURST_5_PHOTOS", nil), @"continuous_shot_2"],
                @(BURST_NUMBER_10):@[NSLocalizedString(@"SETTING_BURST_10_PHOTOS", nil), @"continuous_shot_3"]};*/
}

-(NSDictionary *)powerFrequencyDict
{
  return @{@(LIGHT_FREQUENCY_50HZ):NSLocalizedString(@"SETTING_POWER_SUPPLY_50", nil),
           @(LIGHT_FREQUENCY_60HZ):NSLocalizedString(@"SETTING_POWER_SUPPLY_60", nil)};
}

-(NSDictionary *)dateStampDict
{
    return @{};/*@{@(DATE_STAMP_OFF):NSLocalizedString(@"SETTING_DATESTAMP_OFF", nil),
                @(DATE_STAMP_DATE):NSLocalizedString(@"SETTING_DATESTAMP_DATE", nil),
                @(DATE_STAMP_DATE_TIME):NSLocalizedString(@"SETTING_DATESTAMP_DATE_TIME", nil)};*/
}

-(NSDictionary *)timelapseIntervalDict
{
  return @{@(0):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_OFF", nil),
           @(1):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_1_S", nil),
//           @(0x0002):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_5_S", nil),
           @(3):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_3_S", nil),
//           @(0x0004):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_20_S", nil),
           @(5):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_5_S", nil),
//           @(0x0006):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_1_M", nil),
//           @(0x0007):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_5_M", nil),
//           @(0x0008):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_10_M", nil),
//           @(0x0009):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_30_M", nil),
           @(10):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_10_S", nil),
           @(30):NSLocalizedString(@"SETTING_CAP_TL_INTERVAL_30_S", nil),
           };
}

-(NSDictionary *)timelapseDurationDict
{
  return @{@(0x0001):NSLocalizedString(@"SETTING_CAP_TL_DURATION_OFF", nil),
           @(0x0002):NSLocalizedString(@"SETTING_CAP_TL_DURATION_5_M", nil),
           @(0x0003):NSLocalizedString(@"SETTING_CAP_TL_DURATION_10_M", nil),
           @(0x0004):NSLocalizedString(@"SETTING_CAP_TL_DURATION_15_M", nil),
           @(0x0005):NSLocalizedString(@"SETTING_CAP_TL_DURATION_20_M", nil),
           @(0x0006):NSLocalizedString(@"SETTING_CAP_TL_DURATION_30_M", nil),
           @(0x0007):NSLocalizedString(@"SETTING_CAP_TL_DURATION_60_M", nil),
           @(0xFFFF):NSLocalizedString(@"SETTING_CAP_TL_DURATION_Unlimited", nil)};
}


-(NSDictionary *)noFileNoticeDict
{
  return @{@(SHFileTypeImage):NSLocalizedString(@"NoPhotos", nil),
           @(SHFileTypeVideo):NSLocalizedString(@"NoVideos", nil),
           @(SHFileTypeAudio):NSLocalizedString(@"NoAudioFiles", nil),
           @(SHFileTypeText):NSLocalizedString(@"NoTextFiles", nil)};
}

- (NSDictionary *)tutkModeDict {
    return @{ @(0x01) : @"non",
              @(0x02) : @"p2p",
              @(0x04) : @"relay",
              @(0x08) : @"lan",
             };
}

- (NSDictionary *)tutkErrorDict{
	
    return @{ @(ICH_TUTK_TIME_OUT) : NSLocalizedString(@"kConnectTimedout", nil),
              @(ICH_TUTK_INIT_RDT_FAILED) : NSLocalizedString(@"kConnectTimedout", nil),//NSLocalizedString(@"kInitRdtFailed", nil),
              @(ICH_TUTK_INIT_AVAPI_FAILED) : NSLocalizedString(@"kConnectTimedout", nil),//NSLocalizedString(@"kInitAvapiFailed", nil),
              @(ICH_TUTK_DEVICE_OFFLINE) : NSLocalizedString(@"kDeviceOffline", nil),
              @(ICH_TUTK_DEVICE_IS_SLEEP) : NSLocalizedString(@"kDeviceSleepping", nil),
              @(ICH_TUTK_SETUP_RELAY_FAILED) : NSLocalizedString(@"kConnectTimedout", nil),//NSLocalizedString(@"kSetupRelayModeFailed", nil),
              @(ICH_TUTK_NETWORK_UNREACHABLE) : NSLocalizedString(@"kNetworkUnreachable", nil),
              @(ICH_TUTK_DEVICE_ALREADY_CONNECTED) : NSLocalizedString(@"kDeviceConnectedByOtherUser", nil),
              @(ICH_TUTK_CAN_NOT_FIND_DEVICE) : NSLocalizedString(@"kCannotFindDevice", nil),
              @(ICH_TUTK_IOTC_ER_DEVICE_EXCEED_MAX_SESSION) : NSLocalizedString(@"kConnectingExceedMaxSession", nil),
              @(ICH_TUTK_IOTC_CONNECTION_UNKNOWN_ER) : NSLocalizedString(@"kConnectTimedout", nil),//NSLocalizedString(@"kConnectionUnknownError", nil),
              @(ICH_QR_USEABORT) : NSLocalizedString(@"kConnectTimedout", nil),//NSLocalizedString(@"kQrCodeAccessHasExpired", nil),
              @(ICH_SESSION_PASSWORD_ERR) : NSLocalizedString(@"kConnectTimedout", nil),//@"password error, verify failed.",
              };
}

@end
