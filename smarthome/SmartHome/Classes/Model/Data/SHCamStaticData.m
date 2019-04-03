//
//  WifiCamStaticData.m
//  WifiCamMobileApp
//
//  Created by Sunmedia Apple on 14-6-24.
//  Copyright (c) 2014年 iCatchTech. All rights reserved.
//

#import "SHCamStaticData.h"

@interface SHCamStaticData ()

@property (nonatomic, assign) BOOL backToHome;

@end

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
              @(ICH_PLAYING_VIDEO_BY_OTHERS): NSLocalizedString(@"kPlayingVideoByOthers", nil),
              @(ICH_PREVIEWING_BY_OTHERS): NSLocalizedString(@"kPreviewingByOthers", nil),
              @(ICH_ERR_DEVICE_LOCAL_PLAYBACK): NSLocalizedString(@"kLocalPlaybackDescription", nil),
              };
}

- (NSDictionary *)monthStringDict {
    return @{
             @"01": NSLocalizedString(@"kJanuary", nil),
             @"02": NSLocalizedString(@"kFebruary", nil),
             @"03": NSLocalizedString(@"kMarch", nil),
             @"04": NSLocalizedString(@"kApril", nil),
             @"05": NSLocalizedString(@"kMay", nil),
             @"06": NSLocalizedString(@"kJune", nil),
             @"07": NSLocalizedString(@"kJuly", nil),
             @"08": NSLocalizedString(@"kAugust", nil),
             @"09": NSLocalizedString(@"kSeptember", nil),
             @"10": NSLocalizedString(@"kOctober", nil),
             @"11": NSLocalizedString(@"kNovember", nil),
             @"12": NSLocalizedString(@"kDecember", nil),
             };
}

- (NSArray *)streamQualityArray {
    return @[NSLocalizedString(@"kResolution_Smooth", nil),
             NSLocalizedString(@"kResolution_HD", nil),
             ];
}

- (void)setBackToHomeState:(BOOL)state {
    self.backToHome = state;
}

- (BOOL)isBackToHome {
    return self.backToHome;
}

@end
