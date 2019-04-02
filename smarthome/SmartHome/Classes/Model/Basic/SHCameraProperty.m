//
//  SHCamCamera.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCameraProperty.h"

@implementation SHCameraProperty

- (void)cleanCurrentCameraAllProperty {
    self.vidRecDurationData = nil;
    self.sleepTimeData = nil;
    self.memorySizeData = nil;
    self.recStatusData = nil;
    self.pushMsgStatusData = nil;
    self.fasterConnectionData = nil;
    self.serverOpened = NO;
    self.curBatteryLevel = nil;
    self.tamperalarmData = nil;
    self.aboutData = nil;
    
    self.mute = NO;
    self.talk = NO;
    self.avslayer = nil;
    self.avslayerFrame = CGRectZero;
    self.sdCardResult = nil;
    self.SDUseableSize = 0;
    self.curChargeStatus = nil;
    
    self.clientCount = 0;
    self.noTalking = 0;
}

- (void)updateSDCardInfo:(SHCameraObject *)shCamObj {
    self.memorySizeData = nil;
//    [shCamObj.controler.propCtrl retrieveSDCardFreeSpaceSizeWithCamera:shCamObj curResult:nil];
}

- (void)cleanCacheFormat {
    if (_videoFormat) {
        delete _videoFormat;
        _videoFormat = NULL;
    }
    
    if (_audioFormat) {
        delete _audioFormat;
        _audioFormat = NULL;
    }
}

- (void)cleanCacheData {
    _serverOpened = NO;
    _mute = NO;
    _curAudioPts = 0.0;
    _talk = NO;
}

- (void)setServerOpened:(BOOL)serverOpened {
    @synchronized (self) {
        _serverOpened = serverOpened;
    }
}

@end
