//
//  SHVideoSize.m
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHVideoSize.h"

@interface SHVideoSize ()

@property (nonatomic) SHCameraObject *shCamObj;

@end

@implementation SHVideoSize

+ (instancetype)videoSizeWithCamera:(SHCameraObject *)cameraObj {
    SHVideoSize *vs = [[self alloc] init];
    vs.shCamObj = cameraObj;
    
    return vs;
}

- (SHSettingData *)prepareDataForVideoSize {
//    NSDictionary *videoSizeTable = [[SHCamStaticData instance] videoSizeDict];
    NSString *curVideoSize = [self retrieveCurrentVideoSize];
    NSArray *supVS = [self retrieveSupportedVideoSize:curVideoSize];
    
    SHSettingData *vsData = [[SHSettingData alloc] init];
    vsData.textLabel = NSLocalizedString(@"ALERT_TITLE_SET_VIDEO_RESOLUTION", @"");
    vsData.detailTextLabel = curVideoSize; //[[videoSizeTable objectForKey:curVideoSize] firstObject];
    vsData.detailType = SettingDetailTypeVideoSize;
    vsData.detailData = supVS[1];
    vsData.detailLastItem = [supVS.lastObject integerValue];
    vsData.detailOriginalData = supVS.firstObject;
    
    return vsData;
}

- (NSString *)retrieveCurrentVideoSize {
    if (!_curResult) {
        SHGettingProperty *currentVSPro = [SHGettingProperty gettingPropertyWithControl:_shCamObj.sdk.control];
        [currentVSPro addProperty:TRANS_PROP_CAMERA_VIDEO_SIZE];
        _curResult = [currentVSPro submit];
    }
    
    SHPropertyQueryResult *result = _curResult;

    NSString *curVideoSize = [result praseString:TRANS_PROP_CAMERA_VIDEO_SIZE];
    SHLogInfo(SHLogTagAPP, @"retrieveCurrentVideoSize: %@", curVideoSize);
    
    return curVideoSize;
}

- (NSArray *)retrieveSupportedVideoSize:(NSString *)curVideoSize {
    if (_shCamObj.cameraProperty.fwUpdate || ![_shCamObj.controler.propCtrl.ssp containsKey:@"SupportedVideoSize"]) {
        __block int index = 0;
        __block NSMutableArray *vVSsArray = nil;
        __block NSMutableArray *vOriginalVSsArray = nil;
        
        dispatch_sync([_shCamObj.sdk sdkQueue], ^{
            if (!_supResult) {
                SHGettingSupportedProperty *supportVS = [SHGettingSupportedProperty gettingSupportedPropertyWithControl:_shCamObj.sdk.control];
                [supportVS addProperty:TRANS_PROP_CAMERA_VIDEO_SIZE];
                _supResult = [supportVS submit];
            }
            
            SHPropertyQueryResult *result =_supResult;
            
            int i = 0;
            BOOL InvalidSelectedIndex = NO;
            
            list<NSString *> vVSs = *[result praseRangeListString:TRANS_PROP_CAMERA_VIDEO_SIZE];
            
            vVSsArray = [[NSMutableArray alloc] initWithCapacity:vVSs.size()];
            vOriginalVSsArray = [[NSMutableArray alloc] initWithCapacity:vVSs.size()];
//            NSDictionary *videoSizeDict = [[SHCamStaticData instance] videoSizeDict];
            
            for (list<NSString *>::iterator it = vVSs.begin(); it != vVSs.end(); ++it, ++i) {
                SHLogInfo(SHLogTagAPP, "retrieveSupportedVideoSize: %@", *it);
                if (*it) {
                    [vOriginalVSsArray addObject:*it];
                    
                    NSString *key = [NSString stringWithFormat:@"%@", (*it)];
                    NSArray *sizeArray = [key componentsSeparatedByString:@" "];
                    
                    if (sizeArray[1]) {
                        NSString *videoSize = [NSString stringWithFormat:@"%@ %@fps %@", sizeArray.firstObject, sizeArray[1], sizeArray.lastObject];
                        
                        if (videoSize) {
                            [vVSsArray addObject:videoSize];
                        }
                        
                        if ([curVideoSize isEqualToString:*it] && !InvalidSelectedIndex) {
                            index = i;
                            InvalidSelectedIndex = YES;
                        }
                    }
                }
                
//                NSString *key = [NSString stringWithFormat:@"%@", (*it)];
//                NSArray   *a = [videoSizeDict objectForKey:key];
//                NSString  *first = [a firstObject];
//                NSString  *last = [a lastObject];
//
//                if (last) {
//                    NSString *videoSize = [first stringByAppendingFormat:@" %@", last];
//
//                    if (videoSize) {
//                        [vVSsArray addObject:videoSize];
//                    }
//
//                    if ([curVideoSize isEqualToString:*it] && !InvalidSelectedIndex) {
//                        index = i;
//                        InvalidSelectedIndex = YES;
//                    }
//                }
            }
            
            if (!InvalidSelectedIndex) {
                SHLogError(SHLogTagAPP, @"Undefined Number");
                index = UNDEFINED_NUM;
            }
            
            if (vOriginalVSsArray && vOriginalVSsArray.count) {
                [_shCamObj.controler.propCtrl.ssp.sspDict setObject:vOriginalVSsArray forKey:@"SupportedVideoSize"];
            }
        });
        
        return @[vOriginalVSsArray, vVSsArray, @(index)];
    } else {
        return [self loadLocalSupportedVideoSize:curVideoSize];
    }
}

- (NSArray *)loadLocalSupportedVideoSize:(NSString *)curVideoSize {
    __block int index = 0;
    __block NSMutableArray *vVSsArray = nil;
    __block NSMutableArray *vOriginalVSsArray = nil;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        BOOL InvalidSelectedIndex = NO;
        
        vOriginalVSsArray = [_shCamObj.controler.propCtrl.ssp.sspDict objectForKey:@"SupportedVideoSize"];
        vVSsArray = [[NSMutableArray alloc] initWithCapacity:vOriginalVSsArray.count];

//        NSDictionary *videoSizeDict = [[SHCamStaticData instance] videoSizeDict];
        
        for (int i = 0; i < vOriginalVSsArray.count; i++) {
            NSString *temp = vOriginalVSsArray[i];
            SHLogInfo(SHLogTagAPP, "loadLocalSupportedVideoSize: %@", temp);
            
            NSString *key = [NSString stringWithFormat:@"%@", temp];
            NSArray *sizeArray = [key componentsSeparatedByString:@" "];
            
            if (sizeArray[1]) {
                NSString *videoSize = [NSString stringWithFormat:@"%@ %@fps %@", sizeArray.firstObject, sizeArray[1], sizeArray.lastObject];
                
                if (videoSize) {
                    [vVSsArray addObject:videoSize];
                }
                
                if ([curVideoSize isEqualToString:temp] && !InvalidSelectedIndex) {
                    index = i;
                    InvalidSelectedIndex = YES;
                }
            }
            
//            NSString *key = [NSString stringWithFormat:@"%@", temp];
//            NSArray   *a = [videoSizeDict objectForKey:key];
//            NSString  *first = [a firstObject];
//            NSString  *last = [a lastObject];
//
//            if (last) {
//                NSString *videoSize = [first stringByAppendingFormat:@" %@", last];
//
//                if (videoSize) {
//                    [vVSsArray addObject:videoSize];
//                }
//
//                if ([curVideoSize isEqualToString:temp] && !InvalidSelectedIndex) {
//                    index = i;
//                    InvalidSelectedIndex = YES;
//                }
//            }
        }
        
        if (!InvalidSelectedIndex) {
            SHLogError(SHLogTagAPP, @"Undefined Number");
            index = UNDEFINED_NUM;
        }
    });
    
    return @[vOriginalVSsArray, vVSsArray, @(index)];
}

- (BOOL)changeVideoSize:(NSString *)newVideoSize {
    __block BOOL retVal = NO;
    
    dispatch_sync([_shCamObj.sdk sdkQueue], ^{
        SHSettingProperty *currentVS = [SHSettingProperty settingPropertyWithControl:_shCamObj.sdk.control];
        [currentVS addProperty:TRANS_PROP_CAMERA_VIDEO_SIZE withStringValue:newVideoSize];
        retVal = [currentVS submit];
    });
    
    return retVal;
}

@end
