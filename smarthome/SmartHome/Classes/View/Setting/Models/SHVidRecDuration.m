//
//  SHVidRecDuration.m
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHVidRecDuration.h"

@implementation SHVidRecDuration

+ (instancetype)vidRecDurationWithCamera:(SHCameraObject *)cameraObj {
//    SHVidRecDuration *vrd = [[self alloc] init];
//    vrd.control = control;
//    
//    return vrd;
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_DET_VID_REC_DURATION];
}

- (SHSettingData *)prepareDataForVidRecDuration {
//    int curVidRecDuration = [self retrieveCurrentVidRecDuration];
//    SHRangeItem *item = [self retrieveSupportedVidRecDuration];
//    
//    SHSettingData *vidRecDurationData = [[SHSettingData alloc] init];
//    vidRecDurationData.textLabel = NSLocalizedString(@"SETTING_VidRecDuration", @"");
//    vidRecDurationData.detailTextLabel = [NSString stringWithFormat:@"%ds", curVidRecDuration];
//    vidRecDurationData.detailType = SettingDetailTypeVidRecDuration;
//    vidRecDurationData.detailData = @[item];
//    
//    return vidRecDurationData;
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_VID_REC_DURATION", @"") andUnit:@"s" andSettingDetailType:SettingDetailTypeVidRecDuration];
}

- (int)retrieveCurrentVidRecDuration {
//    SHGettingProperty *currentVidRecDurationPro = [SHGettingProperty gettingPropertyWithControl:_control];
//    [currentVidRecDurationPro addProperty:TRANS_PROP_DET_VID_REC_DURATION];
//    SHPropertyQueryResult *result = [currentVidRecDurationPro submit];
//    
//    int curVidRecDuration = [result praseInt:TRANS_PROP_DET_VID_REC_DURATION];
//    SHLogInfo(SHLogTagAPP, @"retrieveCurrentVidRecDuration: %d", curVidRecDuration);
//    
//    return curVidRecDuration;
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedVidRecDuration {
//    __block SHRangeItem *item = nil;
//    
//    dispatch_sync([[SHSDK sharedSHSDK] sdkQueue], ^{
//        SHGettingSupportedProperty *supportVRD = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_control];
//        [supportVRD addProperty:TRANS_PROP_DET_VID_REC_DURATION];
//        SHPropertyQueryResult *result = [supportVRD submit];
//        item = [result praseRangeItem:TRANS_PROP_DET_VID_REC_DURATION];
//    });
//    
//    return item;
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeVidRecDuration:(int)newVidRecDuration {
//    SHSettingProperty *currentVidRecDuration = [SHSettingProperty settingPropertyWithControl:_control];
//    [currentVidRecDuration addProperty:TRANS_PROP_DET_VID_REC_DURATION withIntValue:newVidRecDuration];
//    BOOL retVal = [currentVidRecDuration submit];
//    
//    return retVal;
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newVidRecDuration];
}

@end
