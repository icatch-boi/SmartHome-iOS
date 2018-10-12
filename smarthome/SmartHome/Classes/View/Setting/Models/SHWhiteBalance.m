//
//  SHWhiteBalance.m
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHWhiteBalance.h"

@interface SHWhiteBalance ()

@property (nonatomic) SHCameraObject *shCamObj;

@end

@implementation SHWhiteBalance

+ (instancetype)whiteBalanceWithCamera:(SHCameraObject *)cameraObj {
    SHWhiteBalance *wb = [[self alloc] init];
    wb.shCamObj = cameraObj;
    
    return wb;
}

- (SHSettingData *)prepareDataForWhiteBalance {
    NSDictionary *whiteBalanceTable = [[SHCamStaticData instance] whiteBalanceDict];
    int curWhiteBalance = [self retrieveCurrentWhiteBalance];
    NSArray *supWB = [self retrieveSupportedWhiteBalance:curWhiteBalance];
    
    SHSettingData *wbData = [[SHSettingData alloc] init];
    wbData.textLabel = NSLocalizedString(@"SETTING_AWB", @"");
    wbData.detailTextLabel = [whiteBalanceTable objectForKey:@(curWhiteBalance)];
    wbData.detailType = SettingDetailTypeWhiteBalance;
    wbData.detailData = supWB[1];
    wbData.detailLastItem = [supWB.lastObject integerValue];
    wbData.detailOriginalData = supWB.firstObject;
    
    return wbData;
}

- (int)retrieveCurrentWhiteBalance {
    if (!_curResult) {
        SHGettingProperty *currentWB = [SHGettingProperty gettingPropertyWithControl:_shCamObj.sdk.control];
        [currentWB addProperty:TRANS_PROP_CAMERA_WHITE_BALANCE];
        _curResult = [currentWB submit];
    }

    SHPropertyQueryResult *result =_curResult;

    int curWhiteBalance = [result praseInt:TRANS_PROP_CAMERA_WHITE_BALANCE];
    SHLogInfo(SHLogTagAPP, @"curWhiteBalance: %d", curWhiteBalance);
    
    return curWhiteBalance;
}

- (NSArray *)retrieveSupportedWhiteBalance:(int)curWhiteBalance {
    if (_shCamObj.cameraProperty.fwUpdate || ![_shCamObj.controler.propCtrl.ssp containsKey:@"SupportedWhiteBalance"]) {
        __block int index = 0;
        __block NSMutableArray *vWBsArray = nil;
        __block NSMutableArray *vOriginalWBsArray = nil;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            if (!_supResult) {
                SHGettingSupportedProperty *supportWB = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_shCamObj.sdk.control];
                [supportWB addProperty:TRANS_PROP_CAMERA_WHITE_BALANCE];
                _supResult = [supportWB submit];
            }
            
            SHPropertyQueryResult *result =_supResult;
            
            int i = 0;
            BOOL InvalidSelectedIndex = NO;
            
            list<int> vWBs = *[result praseRangeListInt:TRANS_PROP_CAMERA_WHITE_BALANCE];
            
            vWBsArray = [[NSMutableArray alloc] initWithCapacity:vWBs.size()];
            vOriginalWBsArray= [[NSMutableArray alloc] initWithCapacity:vWBs.size()];
            NSDictionary *whiteBalanceDict = [[SHCamStaticData instance] whiteBalanceDict];
            
            for (list<int>::iterator it = vWBs.begin(); it != vWBs.end(); ++it, ++i) {
                SHLogInfo(SHLogTagAPP, "retrieveSupportedWhiteBalance: %d", *it);
                
                if (*it) {
                    [vOriginalWBsArray addObject:@(*it)];
                }
                
                NSString *whiteBalance = [whiteBalanceDict objectForKey:@(*it)];
                
                if (whiteBalance) {
                    [vWBsArray addObject:whiteBalance];
                }
                
                if (*it == curWhiteBalance && !InvalidSelectedIndex) {
                    index = i;
                    InvalidSelectedIndex = YES;
                }
            }
            
            if (!InvalidSelectedIndex) {
                SHLogError(SHLogTagAPP, @"Undefined Number");
                index = UNDEFINED_NUM;
            }
            
            if (vOriginalWBsArray.count && vOriginalWBsArray) {
                [_shCamObj.controler.propCtrl.ssp.sspDict setObject:vOriginalWBsArray forKey:@"SupportedWhiteBalance"];
            }
        });
        
        return @[vOriginalWBsArray, vWBsArray, @(index)];
    } else {
        return [self loadLocalSupportedWhiteBalance:curWhiteBalance];
    }
}

- (NSArray *)loadLocalSupportedWhiteBalance:(int)curWhiteBalance {
    __block int index = 0;
    __block NSMutableArray *vWBsArray = nil;
    __block NSMutableArray *vOriginalWBsArray = nil;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        BOOL InvalidSelectedIndex = NO;
        
        vOriginalWBsArray= [_shCamObj.controler.propCtrl.ssp.sspDict objectForKey:@"SupportedWhiteBalance"];
        vWBsArray = [[NSMutableArray alloc] initWithCapacity:vOriginalWBsArray.count];

        NSDictionary *whiteBalanceDict = [[SHCamStaticData instance] whiteBalanceDict];
        
        for (int i = 0; i < vOriginalWBsArray.count; i++) {
            NSNumber *temp = vOriginalWBsArray[i];
            SHLogInfo(SHLogTagAPP, "loadLocalSupportedWhiteBalance: %ld", (long)temp.integerValue);
            
            NSString *whiteBalance = [whiteBalanceDict objectForKey:temp];
            
            if (whiteBalance) {
                [vWBsArray addObject:whiteBalance];
            }
            
            if (temp.integerValue == curWhiteBalance && !InvalidSelectedIndex) {
                index = i;
                InvalidSelectedIndex = YES;
            }
        }
        
        if (!InvalidSelectedIndex) {
            SHLogError(SHLogTagAPP, @"Undefined Number");
            index = UNDEFINED_NUM;
        }
    });
    
    return @[vOriginalWBsArray, vWBsArray, @(index)];
}

- (BOOL)changeWhiteBalance:(int)newWhiteBalance {
    __block BOOL retVal = NO;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        SHSettingProperty *currentWB = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
        [currentWB addProperty:TRANS_PROP_CAMERA_WHITE_BALANCE withIntValue:newWhiteBalance];
        retVal = [currentWB submit];
    });
    
    return retVal;
}

@end
