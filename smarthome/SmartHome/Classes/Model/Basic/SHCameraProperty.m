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
    self.whiteBalanceData = nil;
    self.lightFrequencyData = nil;
    self.videoSizeData = nil;
    self.pirData = nil;
    self.cameraBrightnessData = nil;
    self.vidRecDurationData = nil;
    self.micVolumeData = nil;
    self.speakerVolumeData = nil;
    self.sleepTimeData = nil;
    self.memorySizeData = nil;
    self.recStatusData = nil;
    self.pushMsgStatusData = nil;
    self.fasterConnectionData = nil;
}

//- (NSMutableArray *)downloadArray {
//    if (!_downloadArray) {
//        _downloadArray = [NSMutableArray array];
//    }
//    
//    return _downloadArray;
//}

- (BOOL)checkSupportPropertyExist {
    return self.whiteBalanceData && self.lightFrequencyData && self.videoSizeData && self.pirData && self.cameraBrightnessData && self.vidRecDurationData && self.micVolumeData && self.speakerVolumeData && self.sleepTimeData ? YES : NO;
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
