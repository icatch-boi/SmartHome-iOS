//
//  SHPir.m
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPir.h"

@interface SHPir ()

@end

@implementation SHPir

+ (instancetype)pirWithCamera:(SHCameraObject *)cameraObj {
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_DET_PIR_SENSITIVITY];
}

- (SHSettingData *)prepareDataForPir {
//    int curPir = [self retrieveCurrentPir];
//    SHRangeItem *item = [self retrieveSupportedPir];
//    
//    SHSettingData *pirData = [[SHSettingData alloc] init];
//    pirData.textLabel = NSLocalizedString(@"SETTING_PIR", @"");
//    pirData.detailTextLabel = [NSString stringWithFormat:@"%d%%", curPir];
//    pirData.detailType = SettingDetailTypePir;
//    pirData.detailData = @[item];
//    
//    return pirData;
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_PIR_SENSITIVITY", @"") andUnit:@"%" andSettingDetailType:SettingDetailTypePir];
}

- (int)retrieveCurrentPir {
//    SHGettingProperty *currentPirPro = [SHGettingProperty gettingPropertyWithControl:_control];
//    [currentPirPro addProperty:TRANS_PROP_DET_PIR_SENSITIVITY];
//    SHPropertyQueryResult *result = [currentPirPro submit];
//    
//    int curPir = [result praseInt:TRANS_PROP_DET_PIR_SENSITIVITY];
//    SHLogInfo(SHLogTagAPP, @"retrieveCurrentPir: %d", curPir);
//    
//    return curPir;
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedPir {
//    __block SHRangeItem *item = nil;
//    
//    dispatch_sync([[SHSDK sharedSHSDK] sdkQueue], ^{
//        SHGettingSupportedProperty *supportLF = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_control];
//        [supportLF addProperty:TRANS_PROP_DET_PIR_SENSITIVITY];
//        SHPropertyQueryResult *result = [supportLF submit];
//        item = [result praseRangeItem:TRANS_PROP_DET_PIR_SENSITIVITY];
//    });
//     
//    return item;
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changePir:(int)newPir {
//    SHSettingProperty *currentPir = [SHSettingProperty settingPropertyWithControl:_control];
//    [currentPir addProperty:TRANS_PROP_DET_PIR_SENSITIVITY withIntValue:newPir];
//    BOOL retVal = [currentPir submit];
//    
//    return retVal;
    return [super changeRangeItemValueWithPropertyID:self.propertyID andNewValue:newPir];
}

@end
