//
//  SHLightFrequency.m
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHLightFrequency.h"

@interface SHLightFrequency ()

@property (nonatomic) SHCameraObject *shCamObj;

@end

@implementation SHLightFrequency

+ (instancetype)lightFrequencyWithCamera:(SHCameraObject *)cameraObj; {
    SHLightFrequency *lf = [[self alloc] init];
    lf.shCamObj = cameraObj;
    
    return lf;
}

- (SHSettingData *)prepareDataForLightFrequency {
    NSDictionary *lightFrequencyTable = [[SHCamStaticData instance] powerFrequencyDict];
    int curLightFrequency = [self retrieveCurrentLightFrequency];
    NSArray *supLF = [self retrieveSupportedLightFrequency:curLightFrequency];
    
    SHSettingData *lfData = [[SHSettingData alloc] init];
    lfData.textLabel = NSLocalizedString(@"SETTING_POWER_SUPPLY", @"");
    lfData.detailTextLabel = [lightFrequencyTable objectForKey:@(curLightFrequency)];
    lfData.detailType = SettingDetailTypePowerFrequency;
    lfData.detailData = supLF[1];
    lfData.detailLastItem = [supLF.lastObject integerValue];
    lfData.detailOriginalData = supLF.firstObject;
    
    return lfData;
}

- (int)retrieveCurrentLightFrequency {
    if (!_curResult) {
        SHGettingProperty *currentLFPro = [SHGettingProperty gettingPropertyWithControl:_shCamObj.sdk.control];
        [currentLFPro addProperty:TRANS_PROP_CAMERA_LIGHT_FREQUENCY];
        _curResult = [currentLFPro submit];
    }
    
    SHPropertyQueryResult *result =_curResult;

    int curLightFrequency = [result praseInt:TRANS_PROP_CAMERA_LIGHT_FREQUENCY];
    SHLogInfo(SHLogTagAPP, @"curLightFrequency: %d", curLightFrequency);
    
    return curLightFrequency;
}

- (NSArray *)retrieveSupportedLightFrequency:(int)curLightFrequency {
    if (_shCamObj.cameraProperty.fwUpdate || ![_shCamObj.controler.propCtrl.ssp containsKey:@"SupportedLightFrequency"]) {
        __block int index = 0;
        __block NSMutableArray *vLFsArray = nil;
        __block NSMutableArray *vOriginalLFsArray = nil;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            if (!_supResult) {
                SHGettingSupportedProperty *supportLF = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_shCamObj.sdk.control];
                [supportLF addProperty:TRANS_PROP_CAMERA_LIGHT_FREQUENCY];
                _supResult = [supportLF submit];
            }
            
            SHPropertyQueryResult *result =_supResult;
            
            int i = 0;
            BOOL InvalidSelectedIndex = NO;
            
            list<int> vLFs = *[result praseRangeListInt:TRANS_PROP_CAMERA_LIGHT_FREQUENCY];
            
            vLFsArray = [[NSMutableArray alloc] initWithCapacity:vLFs.size()];
            vOriginalLFsArray = [[NSMutableArray alloc] initWithCapacity:vLFs.size()];
            NSDictionary *lightFrequencyDict = [[SHCamStaticData instance] powerFrequencyDict];
            
            for (list<int>::iterator it = vLFs.begin(); it != vLFs.end(); ++it, ++i) {
                SHLogInfo(SHLogTagAPP, "retrieveSupportedLightFrequency: %d", *it);
                
                if (*it) {
                    [vOriginalLFsArray addObject:@(*it)];
                }
                
                NSString *whiteBalance = [lightFrequencyDict objectForKey:@(*it)];
                
                if (whiteBalance) {
                    [vLFsArray addObject:whiteBalance];
                }
                
                if (*it == curLightFrequency && !InvalidSelectedIndex) {
                    index = i;
                    InvalidSelectedIndex = YES;
                }
            }
            
            if (!InvalidSelectedIndex) {
                SHLogError(SHLogTagAPP, @"Undefined Number");
                index = UNDEFINED_NUM;
            }
            
            if (vOriginalLFsArray && vOriginalLFsArray.count) {
                [self.shCamObj.controler.propCtrl.ssp.sspDict setObject:vOriginalLFsArray forKey:@"SupportedLightFrequency"];
            }
        });
        
        return @[vOriginalLFsArray, vLFsArray, @(index)];
    } else {
        return [self loadLocalSupportedLightFrequency:curLightFrequency];
    }
}

- (NSArray *)loadLocalSupportedLightFrequency:(int)curLightFrequency {
    __block int index = 0;
    __block NSMutableArray *vLFsArray = nil;
    __block NSMutableArray *vOriginalLFsArray = nil;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        BOOL InvalidSelectedIndex = NO;
        
        vOriginalLFsArray = [_shCamObj.controler.propCtrl.ssp.sspDict objectForKey:@"SupportedLightFrequency"];
        vLFsArray = [[NSMutableArray alloc] initWithCapacity:vOriginalLFsArray.count];

        NSDictionary *lightFrequencyDict = [[SHCamStaticData instance] powerFrequencyDict];
        
        for (int i = 0; i < vOriginalLFsArray.count; i++) {
            NSNumber *temp = vOriginalLFsArray[i];
            SHLogInfo(SHLogTagAPP, "loadLocalSupportedLightFrequency: %zd", temp.integerValue);
            
            NSString *whiteBalance = [lightFrequencyDict objectForKey:temp];
            
            if (whiteBalance) {
                [vLFsArray addObject:whiteBalance];
            }
            
            if (temp.integerValue == curLightFrequency && !InvalidSelectedIndex) {
                index = i;
                InvalidSelectedIndex = YES;
            }
        }
        
        if (!InvalidSelectedIndex) {
            SHLogError(SHLogTagAPP, @"Undefined Number");
            index = UNDEFINED_NUM;
        }
    });
    
    return @[vOriginalLFsArray, vLFsArray, @(index)];
}

- (BOOL)changeLightFrequency:(int)newLightFrequency {
    __block BOOL retVal = NO;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        SHSettingProperty *currentLF = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
        [currentLF addProperty:TRANS_PROP_CAMERA_LIGHT_FREQUENCY withIntValue:newLightFrequency];
        retVal = [currentLF submit];
    });
    
    return retVal;
}

@end
