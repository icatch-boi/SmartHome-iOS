//
//  SHRangeItemManger.m
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHRangeItemData.h"

@interface SHRangeItemData ()

@property (nonatomic) SHCameraObject *shCamObj;

@end

@implementation SHRangeItemData

+ (instancetype)rangeItemDataWithCamera:(SHCameraObject *)cameraObj andPropertyID:(int)propertyID {
    SHRangeItemData *ri = [[self alloc] init];
    ri.shCamObj = cameraObj;
    ri.propertyID = propertyID;

    return ri;
}

- (SHSettingData *)prepareDataForRangeItemWithPropertyID:(int)propertyID andTitle:(NSString *)title andUnit:(NSString *)unit andSettingDetailType:(SettingDetailType)type {
    int proId = propertyID ? propertyID : _propertyID;
    
    int curRangeItemValue = [self retrieveRangeItemCurrentValueWithPropertyID:proId];
//    SHRangeItem *item = [self retrieveRangeItemSupportedValueWithPropertyID:proId];
    
    SHSettingData *riData = [[SHSettingData alloc] init];
    riData.textLabel = title;
    riData.detailTextLabel = [NSString stringWithFormat:@"%d%@", curRangeItemValue, unit];
    riData.detailType = type;
//    riData.detailData = @[item];
    riData.unit = unit;
    riData.propertyID = proId;
    
    return riData;
}

- (int)retrieveRangeItemCurrentValueWithPropertyID:(int)propertyID {
    int proId = propertyID ? propertyID : _propertyID;
    __block int curValue;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        if (!_curResult) {
            SHGettingProperty *currentRIPro = [SHGettingProperty gettingPropertyWithControl:_shCamObj.sdk.control];
            [currentRIPro addProperty:proId];
            _curResult = [currentRIPro submit];
        }

        SHPropertyQueryResult *result = _curResult;
        
        curValue = [result praseInt:proId];
        SHLogInfo(SHLogTagAPP, @"retrieveRangeItemCurrentValueWithPropertyID: %d", curValue);
    });
    
    return curValue;
}

- (SHRangeItem *)retrieveRangeItemSupportedValueWithPropertyID:(int)propertyID {
    int proId = propertyID ? propertyID : _propertyID;
    NSString *key = [NSString stringWithFormat:@"propertyID: %d", proId];

    if (_shCamObj.cameraProperty.fwUpdate || ![_shCamObj.controler.propCtrl.ssp containsKey:key]) {
        __block SHRangeItem *item = nil;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            if (!_rangeResult) {
                SHGettingSupportedProperty *supportRI = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_shCamObj.sdk.control];
                [supportRI addProperty:proId];
                _rangeResult = [supportRI submit];
            }
            
            SHPropertyQueryResult *result = _rangeResult;
            item = [result praseRangeItem:proId];
            
            if (item) {
                NSArray *temp = @[@(item.min), @(item.max), @(item.step)];
                [_shCamObj.controler.propCtrl.ssp.sspDict setObject:temp forKey:key];
            }
        });
        
        return item;
    } else {
        return [self loadLocalRangeItemSupportedValueForKey:key];
    }
}

- (SHRangeItem *)loadLocalRangeItemSupportedValueForKey:(NSString *)key {
    NSArray *temp = [_shCamObj.controler.propCtrl.ssp.sspDict objectForKey:key];
    return [SHRangeItem rangeItemWithData:[temp[0] integerValue] max:[temp[1] integerValue] step:[temp[2] integerValue]];
}

- (BOOL)changeRangeItemValueWithPropertyID:(int)propertyID andNewValue:(int)newValue {
    int proId = propertyID ? propertyID : _propertyID;
    __block BOOL retVal = NO;

    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        SHSettingProperty *currentPro = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
        [currentPro addProperty:proId withIntValue:newValue];
        retVal = [currentPro submit];
    });

    return retVal;
}

@end
