//
//  SHGettingSupportedProperty.m
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHGettingSupportedProperty.h"

@interface SHGettingSupportedProperty ()

@property (nonatomic) Control *control;
@property (nonatomic) list<ICatchTransProperty> *propertyList;

@end

@implementation SHGettingSupportedProperty

- (list<ICatchTransProperty> *)propertyList {
    if (!_propertyList) {
        _propertyList = new list<ICatchTransProperty>;
    }
    
    return _propertyList;
}

+ (instancetype)gettingSupportedPropertyWithControl:(Control *)control {
    SHGettingSupportedProperty *getSupportedProperty = [[SHGettingSupportedProperty alloc] init];
    getSupportedProperty.control = control;
    
    return getSupportedProperty;
}

- (void)addProperty:(int)propertyId {
    ICatchTransProperty *property = [self createGetProperty:propertyId];
    self.propertyList->push_back(*property);
}

- (SHPropertyQueryResult *)submit {
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

- (NSInteger)getPropertyListSize {
    return self.propertyList->size();
}

- (void)clear {
    self.propertyList->clear();
}

- (ICatchTransProperty *)createGetProperty:(int)propertyId {
    ICatchTransProperty* property = nil;
    switch (propertyId) {
        case TRANS_PROP_CAMERA_IMAGE_SIZE:
        case TRANS_PROP_CAMERA_VIDEO_SIZE:
        case TRANS_PROP_CAMERA_WHITE_BALANCE:
        case TRANS_PROP_CAMERA_LIGHT_FREQUENCY:
            property = new ICatchTransProperty(propertyId,0x05);//getsupported
            property->setDataType(0x05);//list
            break;
            
        case TRANS_PROP_DET_PIR_SENSITIVITY:
//        case TRANS_PROP_DET_AUDIO_SENSITIVITY:
        case TRANS_PROP_CAMERA_BRIGHTNESS:
        case TRANS_PROP_DET_VID_REC_DURATION:
        case TRANS_PROP_CAMERA_MIC_VOLUME:
        case TRANS_PROP_CAMERA_SPEAKER_VOLUME:
        case TRANS_PROP_CAMERA_SLEEP_TIME:
            property = new ICatchTransProperty(propertyId,0x05);//get
            property->setDataType(0x00);//int
            break;
            
        default:
            break;
    }
    return property;
}

@end
