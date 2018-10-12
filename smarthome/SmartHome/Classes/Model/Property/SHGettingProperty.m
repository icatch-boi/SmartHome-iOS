//
//  SHGettingProperty.m
//  SmartHome
//
//  Created by yh.zhang on 17/5/15.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHGettingProperty.h"

@interface SHGettingProperty()

@property (nonatomic) Control *control;
@property (nonatomic) list<ICatchTransProperty> *propertyList;

@end

@implementation SHGettingProperty

- (list<ICatchTransProperty> *)propertyList {
    if (!_propertyList) {
        _propertyList = new list<ICatchTransProperty>;
    }
    
    return _propertyList;
}

+ (instancetype)gettingPropertyWithControl:(Control *)control {
    SHGettingProperty *getProperty = [[SHGettingProperty alloc] init];
    getProperty.control = control;
    
    return getProperty;
}

- (void)addProperty:(int)propertyId {
    ICatchTransProperty *property = [self createGetProperty:propertyId];
    self.propertyList->push_back(*property);
}

- (void)addProperty:(int)propertyId withStringValue:(NSString*)stringValue {
    ICatchTransProperty *property = [self createGetProperty:propertyId withStringValue:stringValue];
    self.propertyList->push_back(*property);
}

- (SHPropertyQueryResult *)submit{
    SHPropertyQueryResult *result = nil;
    
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return result;
    }
    
    int retVal = _control->getTransPropertys(*self.propertyList);
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"getTransPropertys succeed.");
        result = [SHPropertyQueryResult  propertyQueryResultWithTransProperty:*self.propertyList];
    } else {
        SHLogError(SHLogTagSDK, @"getTransPropertys failed, ret: %d.", retVal);
    }
    
    return result;
}

- (ICatchTransProperty *)createGetProperty:(int)propertyId{
    ICatchTransProperty* property = nil;
    switch (propertyId) {
        case TRANS_PROP_CAMERA_IMAGE_SIZE:
        case TRANS_PROP_CAMERA_VIDEO_SIZE:
        case TRANS_PROP_REMOTE_DATE_TIME:
        case TRANS_PROP_CAMERA_VERSION:
        case TRANS_PROP_CAMERA_LAST_PREVIEW_TIME:
        case TRANS_PROP_CAMERA_TIME_ZONE:
        case TRANS_PROP_GET_FILES_DATE_TIME_RANGE:
            property = new ICatchTransProperty(propertyId,0x02);//get
            property->setDataType(0x03);//string
            break;
            
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
            property = new ICatchTransProperty(propertyId,0x02);//get
            property->setDataType(0x00);//int
            break;
            
        case TRANS_PROP_GET_FILE_THUMBNAIL:
        case TRANS_PROP_CAMERA_PREVIEW_THUMBNAIL:
            property = new ICatchTransProperty(propertyId,0x02);//get
            property->setDataType(0x04);//data
            break;
            
        default:
            break;
    }
    
    return property;
}

- (ICatchTransProperty *)createGetProperty:(int)propertyId withStringValue:(NSString*)stringValue{
    ICatchTransProperty* property = nil;
    switch (propertyId) {
         case TRANS_PROP_CAMERA_NEW_FILES_COUNT:
            property = new ICatchTransProperty(propertyId,0x02);//get
            property->setDataType(0x00);//return int
            property->setProperty([stringValue UTF8String]);
            break;
              default:
            break;
    }
    
    return property;
}

@end
