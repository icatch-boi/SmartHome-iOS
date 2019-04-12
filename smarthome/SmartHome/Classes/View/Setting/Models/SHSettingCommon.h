//
//  SHSettingCommon.h
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#ifndef SHSettingCommon_h
#define SHSettingCommon_h

typedef enum SettingDetailType{
    SettingDetailTypeWhiteBalance = 0,
    SettingDetailTypePowerFrequency,
    SettingDetailTypeBurstNumber,
    SettingDetailTypeAbout,
    SettingDetailTypeDateStamp,
    SettingDetailTypeTimelapseType,
    SettingDetailTypeTimelapseInterval,
    SetttngDetailTypeTimelapseDuration,
    SettingDetailTypeUpsideDown,
    SettingDetailTypeSlowMotion,
    SettingDetailTypeImageSize,
    SettingDetailTypeVideoSize,
    SettingDetailTypeCaptureDelay,
    SettingDetailTypeLiveSize,
    SettingDetailTypePir,
    SettingDetailTypeCameraBrightness,
    SettingDetailTypeVidRecDuration,
    SettingDetailTypeMICVolume,
    SettingDetailTypeSpeakerVolume,
    SettingDetailTypeSleepTime,
    SettingDetailTypeTimeZone,
    
} SettingDetailType;

enum SHParseError {
    SHInvalidProperty = -2,
};

#import "SHSettingData.h"
#import "SHGettingSupportedProperty.h"
#import "SHPropertyQueryResult.h"
#import "SHGettingProperty.h"
#import "SHSettingProperty.h"

#import "SHAbout.h"
#import "SHRangeItemData.h"
#import "SHVidRecDuration.h"
#import "SHSleepTime.h"

#endif /* SHSettingCommon_h */
