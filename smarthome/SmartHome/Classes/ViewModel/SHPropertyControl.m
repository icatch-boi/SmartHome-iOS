//
//  SHCameraPropertyControl.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPropertyControl.h"

@implementation SHPropertyControl

- (SHSaveSupportedProperty *)ssp {
    if (_ssp == nil) {
        _ssp = [SHSaveSupportedProperty new];
    }
    
    return _ssp;
}

- (SHPropertyQueryResult *)retrieveSettingCurPropertyWithCamera:(SHCameraObject *)shCameraObj {
    __block SHPropertyQueryResult *result = nil;
    
    if (shCameraObj.sdk == nil) {
        SHLogError(SHLogTagAPP, @"CameraObj 'sdk' attribute is nil.");
        return result;
    }
    
    dispatch_sync(shCameraObj.sdk.sdkQueue, ^{
        SHGettingProperty *currentPro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
        
        [currentPro addProperty:TRANS_PROP_DET_VID_REC_DURATION];

        [currentPro addProperty:TRANS_PROP_CAMERA_SLEEP_TIME];
        
        [currentPro addProperty:TRANS_PROP_SD_MEMORY_SIZE];
        
        [currentPro addProperty:TRANS_PROP_DET_VID_REC_STATUS];
        [currentPro addProperty:TRANS_PROP_DET_PUSH_MSG_STATUS];
        [currentPro addProperty:TRANS_PROP_DET_PIR_STATUS];
        
        [currentPro addProperty:TRANS_PROP_CAMERA_VERSION];
        
        [currentPro addProperty:TRANS_PROP_TAMPER_ALARM];
        
        result = [currentPro submit];
    });
    
    return result;
}

- (SHPropertyQueryResult *)retrievePVCurPropertyWithCamera:(SHCameraObject *)shCameraObj {
    __block SHPropertyQueryResult *result = nil;
    
    SHGettingProperty *currentPro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
    
    [currentPro addProperty:TRANS_PROP_CAMERA_BATTERY_LEVEL];
//    [currentPro addProperty:TRANS_PROP_DET_PIR_STATUS];

//    [currentPro addProperty:TRANS_PROP_CAMERA_WIFI_SIGNAL];
    
    [currentPro addProperty:TRANS_PROP_CAMERA_LAST_PREVIEW_TIME];
    [currentPro addProperty:TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL_SIZE];
    
    [currentPro addProperty:TRANS_PROP_CAMERA_VERSION];
    [currentPro addProperty:TRANS_PROP_CAMERA_UPGRADE_FW];

    result = [currentPro submit];
    
    return result;
}

- (SHPropertyQueryResult *)retrieveSettingSupPropertyWithCamera:(SHCameraObject *)shCameraObj {
    __block SHPropertyQueryResult *result = nil;

    if (shCameraObj.cameraProperty.fwUpdate) {
        dispatch_sync(shCameraObj.sdk.sdkQueue, ^{
            SHGettingSupportedProperty *supportedPro = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:shCameraObj.sdk.control];
            
            [supportedPro addProperty:TRANS_PROP_CAMERA_WHITE_BALANCE];
            [supportedPro addProperty:TRANS_PROP_CAMERA_LIGHT_FREQUENCY];
            [supportedPro addProperty:TRANS_PROP_CAMERA_VIDEO_SIZE];
            
            [supportedPro addProperty:TRANS_PROP_DET_PIR_SENSITIVITY];
            [supportedPro addProperty:TRANS_PROP_CAMERA_BRIGHTNESS];
            [supportedPro addProperty:TRANS_PROP_DET_VID_REC_DURATION];
            [supportedPro addProperty:TRANS_PROP_CAMERA_MIC_VOLUME];
            [supportedPro addProperty:TRANS_PROP_CAMERA_SPEAKER_VOLUME];
            [supportedPro addProperty:TRANS_PROP_CAMERA_SLEEP_TIME];
            
            result = [supportedPro submit];
        });
    }

    return result;
}

- (BOOL)factoryResetWithCamera:(SHCameraObject *)shCameraObj {
    return [shCameraObj.sdk factoryReset];
}

- (NSData *)requestThumbnail:(ICatchFile *)file andPropertyID:(int)propertyID andCamera:(SHCameraObject *)shCameraObj {
    return [shCameraObj.sdk requestThumbnail:file andPropertyID:propertyID];
}

- (uint)prepareDataForBatteryLevelWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult
{
    __block uint level = -1;
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_CAMERA_BATTERY_LEVEL];
            SHPropertyQueryResult *result = [pro submit];
            
            level = [result praseInt:TRANS_PROP_CAMERA_BATTERY_LEVEL];
        } else {
            level = [curResult praseInt:TRANS_PROP_CAMERA_BATTERY_LEVEL];
        }
    });

    SHLogInfo(SHLogTagAPP, @"battery level: %d", level);
    return level;
}

- (NSString *)transBatteryLevel2NStr:(unsigned int)value
{
    NSString *retVal = nil;
    
    if (value < 10) {
        retVal = @"vedieo-buttery";
    } else if (value < 20) {
        retVal = @"vedieo-buttery_1";
    } else if (value < 30) {
        retVal = @"vedieo-buttery_2";
    } else if (value < 40) {
        retVal = @"vedieo-buttery_3";
    } else if (value < 50) {
        retVal = @"vedieo-buttery_4";
    } else if (value < 60) {
        retVal = @"vedieo-buttery_5";
    } else if (value < 70) {
        retVal = @"vedieo-buttery_6";
    } else if (value < 80) {
        retVal = @"vedieo-buttery_7";
    } else if (value < 90) {
        retVal = @"vedieo-buttery_8";
    } else if (value < 100) {
        retVal = @"vedieo-buttery_9";
    } else if (value == 100) {
        retVal = @"vedieo-buttery_10";
    }
    
    SHLogInfo(SHLogTagAPP, @"battery level: %d, string: %@", value, retVal);
    return retVal;
}

- (int)prepareDataForChargeStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult
{
    __block int level = -1;
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_CAMERA_CHARGE_STATUS];
            SHPropertyQueryResult *result = [pro submit];
            
            level = [result praseInt:TRANS_PROP_CAMERA_CHARGE_STATUS];
        } else {
            level = [curResult praseInt:TRANS_PROP_CAMERA_CHARGE_STATUS];
        }
    });
    
    SHLogInfo(SHLogTagAPP, @"Charge status: %d", level);
    return level;
}

- (NSString *)prepareDataForPirStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult
{
    __block uint value = -1;
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_DET_PIR_STATUS];
            SHPropertyQueryResult *result = [pro submit];
            
            value = [result praseInt:TRANS_PROP_DET_PIR_STATUS];
        } else {
            value = [curResult praseInt:TRANS_PROP_DET_PIR_STATUS];
        }
    });
    return [self transPirStatus2NStr:value];
}

- (NSString *)transPirStatus2NStr:(unsigned int)value
{
    NSString *retVal = nil;
    
    switch (value) {
        case 0:
            retVal = @"ic_no_pir_detect_24dp";
            break;
            
        case 1:
            retVal = @"ic_pir_detecting_24dp";
            break;
            
        case 2:
            retVal = @"ic_pir_detected_24dp";
            break;
            
        default:
            SHLogError(SHLogTagAPP, @"pir Status Exception.");
            break;
    }
    
    return retVal;
}

- (NSString *)prepareDataForSDCardStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult
{
    uint value = [self retrieveSDCardFreeSpaceSizeWithCamera:shCameraObj curResult:curResult];
    
    return [self transSDCardStatus2NStr:value];
}

- (NSString *)transSDCardStatus2NStr:(int)value
{
    NSString *retVal = nil;
    
    if (value == -1) {
        retVal = @"ic_no_sd_grey_500_24dp";
    } else if (value >= 0) {
        retVal = @"ic_sd_storage_green_700_24dp";
    } else {
        retVal = @"ic_no_sd_grey_500_24dp";
        SHLogError(SHLogTagAPP, @"SDCard Status Exception.");
    }
    
    return retVal;
}

- (NSString *)prepareDataForWifiStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult
{
    __block uint value = -1;
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_CAMERA_WIFI_SIGNAL];
            SHPropertyQueryResult *result = [pro submit];
            
            value = [result praseInt:TRANS_PROP_CAMERA_WIFI_SIGNAL];
        } else {
            value = [curResult praseInt:TRANS_PROP_CAMERA_WIFI_SIGNAL];
        }
    });
    
    return [self transWifiStatus2NStr:value];
}

- (NSString *)transWifiStatus2NStr:(unsigned int)value
{
	SHLogInfo(SHLogTagAPP, @"transWifiStatus2NStr,wifi value is : %d",value);
	
    NSString *retVal = nil;
    
    if (value <= 10) {
        retVal = @"ic_signal_wifi_off_black_24dp";
    } else if (value > 10 && value <= 40) {
        retVal = @"ic_signal_wifi_1_bar_black_24dp";
    }  else if (value > 40 && value <= 80) {
        retVal = @"ic_signal_wifi_2_bar_black_24dp";
    } else if (value > 80 && value <= 90) {
        retVal = @"ic_signal_wifi_3_bar_black_24dp";
    } else if (value > 90) {
        retVal = @"ic_signal_wifi_4_bar_black_24dp";
    } else {
        SHLogError(SHLogTagAPP, @"Wifi Status Exception.");
    }
	SHLogError(SHLogTagAPP, @"SDCard Status Exception.");
	SHLogInfo(SHLogTagAPP, @"transWifiStatus2NStr,return value is : %@",retVal);
    return retVal;
}

- (BOOL)checkSDExistWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    return [self retrieveSDCardFreeSpaceSizeWithCamera:shCameraObj curResult:curResult] == -1 ? NO : YES;
}

- (BOOL)checkSDFullWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    return [self retrieveSDCardFreeSpaceSizeWithCamera:shCameraObj curResult:curResult] == 0 ? YES : NO;
}

- (int)retrieveSDCardFreeSpaceSizeWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    __block int retVal = -2;
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_SD_MEMORY_SIZE];
            SHPropertyQueryResult *result = [pro submit];
            
            retVal = [result praseInt:TRANS_PROP_SD_MEMORY_SIZE];
            
            if (retVal != -2) {
                shCameraObj.cameraProperty.sdCardResult = result;
            }
        } else {
            retVal = [curResult praseInt:TRANS_PROP_SD_MEMORY_SIZE];
        }
    });
    
    return retVal;
}

- (void)updateSDCardFreeSpaceSizeWithCamera:(SHCameraObject *)shCameraObj {
    int memorySize = [self retrieveSDCardFreeSpaceSizeWithCamera:shCameraObj curResult:nil];
    
    if (shCameraObj.cameraProperty.memorySizeData) {
        shCameraObj.cameraProperty.memorySizeData.detailTextLabel = [NSString stringWithFormat:@"%d MB", memorySize];
    } else {
        SHSettingData *memorySizeData = [[SHSettingData alloc] init];
        memorySizeData.textLabel = NSLocalizedString(@"SETTING_MEMORY_SIZE", nil);
        memorySizeData.detailTextLabel = [NSString stringWithFormat:@"%d MB", memorySize];
        
        shCameraObj.cameraProperty.memorySizeData = memorySizeData;
    }
}

- (NSString *)retrieveLastPreviewTimeWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    NSString *pvTime = nil;
    
    if (!curResult) {
        SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
        [pro addProperty:TRANS_PROP_CAMERA_LAST_PREVIEW_TIME];
        SHPropertyQueryResult *result = [pro submit];
        
        pvTime = [result praseString:TRANS_PROP_CAMERA_LAST_PREVIEW_TIME];
    } else {
        pvTime = [curResult praseString:TRANS_PROP_CAMERA_LAST_PREVIEW_TIME];
    }
    
    return pvTime;
}

- (uint)retrievePreviewThumbnailSizeWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    uint thumbnailSize = -1;
    
    if (!curResult) {
        SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
        [pro addProperty:TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL_SIZE];
        SHPropertyQueryResult *result = [pro submit];
        
        thumbnailSize = [result praseInt:TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL_SIZE];
    } else {
        thumbnailSize = [curResult praseInt:TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL_SIZE];
    }
    
    return thumbnailSize;
}

- (UIImage *)retrievePreviewThumbanilWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    UIImage *thumbnail = nil;
    uint thumbnailSize = [self retrievePreviewThumbnailSizeWithCamera:shCameraObj curResult:curResult];
    
    do {
        if (thumbnailSize <= 0) {
            SHLogError(SHLogTagAPP, @"thumbnailSize <= 0");
            break;
        }
        
        ICatchTransProperty *prop = new ICatchTransProperty(TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL, 0x02);
        if (prop == NULL) {
            SHLogError(SHLogTagAPP, @"new ICatchTransProperty failed.");
            break;
        }
        
        prop->setDataType(0x04);//data
        prop->setDataSize(thumbnailSize);
        
        ICatchFrameBuffer *frameBuffer = new ICatchFrameBuffer(thumbnailSize);
        if (frameBuffer == NULL) {
            SHLogError(SHLogTagAPP, @"new ICatchFrameBuffer failed.");
            break;
        }
        
        int retVal = shCameraObj.sdk.control->getTransThumbnail(*prop, frameBuffer);
        if (retVal == ICH_SUCCEED) {
            NSData *imageData = [NSData dataWithBytes:frameBuffer->getBuffer() length:frameBuffer->getFrameSize()];
            thumbnail = [UIImage imageWithData:imageData];
        } else {
            SHLogError(SHLogTagSDK, @"getTransThumbnail failed, ret: %d", retVal);
        }
        
        delete frameBuffer;
        frameBuffer = nil;
        
        delete prop;
        prop = NULL;
    } while (0);
    
    return thumbnail;
}

- (ICatchCameraVersion)retrieveCameraVersionWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult{
    SHPropertyQueryResult *result = curResult;

    if (!result) {
        SHGettingProperty *currentVersion = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
        [currentVersion addProperty:TRANS_PROP_CAMERA_VERSION];
        result = [currentVersion submit];
    }
    
    string jsonStr = [result praseString2:TRANS_PROP_CAMERA_VERSION];
    SHLogInfo(SHLogTagAPP, @"retrieveCameraVersion: %s", jsonStr.c_str());
    
    ICatchCameraVersion cameraInfo;
    ICatchCameraVersion::parseString(jsonStr, cameraInfo);
    
    return cameraInfo;
}

- (BOOL)compareFWVersion:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult {
    BOOL update = NO;
    
    do {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *key = [NSString stringWithFormat:@"%@FWVersion:", shCameraObj.camera.cameraUid];
        
        NSString *firmwareVer = [defaults valueForKey:key];
        
        ICatchCameraVersion version = [self retrieveCameraVersionWithCamera:shCameraObj curResult:curResult];
        NSString *curFirmwareVer = [NSString stringWithFormat:@"%s", version.getFirmwareVer().c_str()];
        
        if (firmwareVer && [firmwareVer isEqualToString:curFirmwareVer]) {
            break;
        }
        
        update = YES;
    } while (0);

    return update;
}

- (uint)retrieveNewFilesCountWithCamera:(SHCameraObject *)shCameraObj pbTime:(NSString *)pbTime {
    uint newFilesCount = 0;
    
    if (pbTime == nil) {
        return newFilesCount;
    }
    
    SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
    [pro addProperty:TRANS_PROP_CAMERA_NEW_FILES_COUNT withStringValue:pbTime];
    SHPropertyQueryResult *result = [pro submit];
    
    newFilesCount = [result praseInt:TRANS_PROP_CAMERA_NEW_FILES_COUNT];

    
    return newFilesCount;
}

- (shared_ptr<ICatchCameraVersion>)retrieveCameraVersionWithCamera:(SHCameraObject *)shCameraObj {
    __block NSString *versionString = nil;
    
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!shCameraObj.curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_CAMERA_VERSION];
            SHPropertyQueryResult *result = [pro submit];
            
            versionString = [result praseString:TRANS_PROP_CAMERA_VERSION];
        } else {
            versionString = [shCameraObj.curResult praseString:TRANS_PROP_CAMERA_VERSION];
        }
    });
    
    SHLogInfo(SHLogTagAPP, @"Camera version: %@", versionString);
    shared_ptr<ICatchCameraVersion> version = make_shared<ICatchCameraVersion>();
    
    ICatchCameraVersion::parseString(versionString.UTF8String, *(version.get()));
    
    return version;
}

- (BOOL)deviceSupportUpgradeWithCamera:(SHCameraObject *)shCameraObj {
    __block int value = -1;
    
    dispatch_sync([shCameraObj.sdk sdkQueue], ^{
        if (!shCameraObj.curResult) {
            SHGettingProperty *pro = [SHGettingProperty gettingPropertyWithControl:shCameraObj.sdk.control];
            [pro addProperty:TRANS_PROP_CAMERA_UPGRADE_FW];
            SHPropertyQueryResult *result = [pro submit];
            
            value = [result praseInt:TRANS_PROP_CAMERA_UPGRADE_FW];
        } else {
            value = [shCameraObj.curResult praseInt:TRANS_PROP_CAMERA_UPGRADE_FW];
        }
    });
    
    BOOL support = (value == 1) ? YES : NO;
    SHLogInfo(SHLogTagAPP, @"Device support upgrade: %d", support);
    
    return support;
}

@end
