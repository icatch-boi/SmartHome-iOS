//
//  SHCameraBrightness.m
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCameraBrightness.h"

@interface SHCameraBrightness ()

@end

@implementation SHCameraBrightness

+ (instancetype)cameraBrightnessWithCamera:(SHCameraObject *)cameraObj {
//    SHCameraBrightness *cb = [[self alloc] init];
//    cb.control = control;
//    
//    return cb;
    
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_CAMERA_BRIGHTNESS];
}

- (SHSettingData *)prepareDataForCameraBrightness {
//    int curCameraBrightness = [self retrieveCurrentCameraBrightness];
//    SHRangeItem *item = [self retrieveSupportedCameraBrightness];
//    
//    SHSettingData *cameraBrightnessData = [[SHSettingData alloc] init];
//    cameraBrightnessData.textLabel = NSLocalizedString(@"SETTING_CameraBrightness", @"");
//    cameraBrightnessData.detailTextLabel = [NSString stringWithFormat:@"%d%%", curCameraBrightness];
//    cameraBrightnessData.detailType = SettingDetailTypeCameraBrightness;
//    cameraBrightnessData.detailData = @[item];
//    
//    return cameraBrightnessData;
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_CAMERA_BRIGHTNESS", @"") andUnit:@"%" andSettingDetailType:SettingDetailTypeCameraBrightness];
}

- (int)retrieveCurrentCameraBrightness {
//    SHGettingProperty *currentCameraBrightnessPro = [SHGettingProperty gettingPropertyWithControl:_control];
//    [currentCameraBrightnessPro addProperty:TRANS_PROP_CAMERA_BRIGHTNESS];
//    SHPropertyQueryResult *result = [currentCameraBrightnessPro submit];
//    
//    int curCameraBrightness = [result praseInt:TRANS_PROP_CAMERA_BRIGHTNESS];
//    SHLogInfo(SHLogTagAPP, @"retrieveCurrentCameraBrightness: %d", curCameraBrightness);
//    
//    return curCameraBrightness;
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedCameraBrightness {
//    __block SHRangeItem *item = nil;
//    
//    dispatch_sync([[SHSDK sharedSHSDK] sdkQueue], ^{
//        SHGettingSupportedProperty *supportCB = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_control];
//        [supportCB addProperty:TRANS_PROP_CAMERA_BRIGHTNESS];
//        SHPropertyQueryResult *result = [supportCB submit];
//        item = [result praseRangeItem:TRANS_PROP_CAMERA_BRIGHTNESS];
//    });
//    
//    return item;
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeCameraBrightness:(int)newCameraBrightness {
//    SHSettingProperty *currentCameraBrightness = [SHSettingProperty settingPropertyWithControl:_control];
//    [currentCameraBrightness addProperty:TRANS_PROP_CAMERA_BRIGHTNESS withIntValue:newCameraBrightness];
//    BOOL retVal = [currentCameraBrightness submit];
//    
//    return retVal;
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newCameraBrightness];
}

@end
