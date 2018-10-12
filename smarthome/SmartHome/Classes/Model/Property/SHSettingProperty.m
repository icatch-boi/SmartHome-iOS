//
//  SHSettingProperty.m
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSettingProperty.h"
#include "type/ICatchTransPropertyID.h"

@interface SHSettingProperty ()

@property (nonatomic) Control *control;
@property (nonatomic) list<ICatchTransProperty> *propertyList;

@end
@implementation SHSettingProperty

- (list<ICatchTransProperty> *)propertyList {
    if (!_propertyList) {
        _propertyList = new list<ICatchTransProperty>;
    }
    
    return _propertyList;
}

+ (instancetype)settingPropertyWithControl:(Control *)control {
    SHSettingProperty *getProperty = [[SHSettingProperty alloc] init];
    getProperty.control = control;
    
    return getProperty;
}

- (void)addProperty:(int)propertyId withIntValue:(int)intValue {
    ICatchTransProperty *property = [self createSetProperty:propertyId withIntValue:intValue];
    self.propertyList->push_back(*property);
}

- (void)addProperty:(int)propertyId withStringValue:(NSString*)stringValue {
    ICatchTransProperty *property = [self createSetProperty:propertyId withStringValue:stringValue];
    self.propertyList->push_back(*property);
}

- (BOOL)submit {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    int retVal = _control->getTransPropertys(*self.propertyList);
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"getTransPropertys succeed.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"getTransPropertys failed, ret: %d.", retVal);
        return NO;
    }
}

- (ICatchTransProperty *)createSetProperty:(int)propertyId withIntValue:(int)intValue {
    ICatchTransProperty* property = nil;
    switch (propertyId) {
        case TRANS_PROP_DET_PIR_STATUS:
        case TRANS_PROP_DET_PIR_SENSITIVITY:
//        case TRANS_PROP_DET_AUDIO_STATUS:
//        case TRANS_PROP_DET_AUDIO_SENSITIVITY:
        case TRANS_PROP_CAMERA_BATTERY_LEVEL:
        case TRANS_PROP_CAMERA_WIFI_SIGNAL:
        case TRANS_PROP_SD_MEMORY_SIZE:
        case TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL_SIZE:
        case TRANS_PROP_CAMERA_BRIGHTNESS:
        case TRANS_PROP_DET_VID_REC_DURATION:
        case TRANS_PROP_CAMERA_SLEEP_TIME:
        case TRANS_PROP_CAMERA_MIC_VOLUME:
        case TRANS_PROP_CAMERA_SPEAKER_VOLUME:
        case TRANS_PROP_CAMERA_WHITE_BALANCE:
        case TRANS_PROP_CAMERA_LIGHT_FREQUENCY:
        case TRANS_PROP_DET_VID_REC_STATUS:
        case TRANS_PROP_DET_PUSH_MSG_STATUS:
        case TRANS_PROP_CAMERA_ULTRA_POWER_SAVING_MODE:
            property = new ICatchTransProperty(propertyId,0x01);//set
            property->setDataType(0x00);//int
            property->setProperty(intValue);
            break;

        default:
            break;
    }
    
    return property;
}

- (ICatchTransProperty *)createSetProperty:(int)propertyId withStringValue:(NSString*)stringValue {
    ICatchTransProperty* property = nil;
    switch (propertyId) {
        case TRANS_PROP_CAMERA_IMAGE_SIZE:
        case TRANS_PROP_CAMERA_VIDEO_SIZE:
        case TRANS_PROP_REMOTE_DATE_TIME:
        case TRANS_PROP_CAMERA_VERSION:
        case TRANS_PROP_CAMERA_LAST_PREVIEW_TIME:
        case TRANS_PROP_CAMERA_TIME_ZONE:
        case TRANS_PROP_GET_FILES_DATE_TIME_RANGE:
        case TRANS_PROP_CAMERA_SET_PASSWORD:
            property = new ICatchTransProperty(propertyId,0x01);//set
            property->setDataType(0x03);//string
            property->setProperty(stringValue.UTF8String);
            break;
        default:
            break;
    }
    
    return property;
}

@end
