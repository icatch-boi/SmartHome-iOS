//
//  SHAbout.m
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHAbout.h"

@interface SHAbout ()

@property (nonatomic) SHCameraObject *shCameraObj;

@end

@implementation SHAbout

+ (instancetype)aboutWithCamera:(SHCameraObject *)cameraObj {
    SHAbout *about = [[self alloc] init];
    about.shCameraObj = cameraObj;
    
    return about;
}

- (SHSettingData *)prepareDataForAbout {
    NSMutableArray *aboutArray = [NSMutableArray array];
    
    NSString *appVersion = NSLocalizedString(@"SETTING_APP_VERSION", nil);
    appVersion = [appVersion stringByReplacingOccurrencesOfString:@"%@" withString:[NSString stringWithFormat:@"%@ (%@)", APP_VERSION, APP_BUILDNUMBER]];
    
    [aboutArray addObject:appVersion];
    
    SDKInfo *sdkInfo = SDKInfo::getInstance();
    string sdkVString = sdkInfo->getSDKVersion();
    NSString *sdkVersion = [NSString stringWithFormat:@"%@：%s", NSLocalizedString(@"kSDKVersionInfo", nil), sdkVString.c_str()];
    [aboutArray addObject:sdkVersion];
    
    ICatchCameraVersion cameraInfo = [self retrieveCameraVersion];
    NSString *hardwareVer = [NSString stringWithFormat:@"HardwareVer: %s", cameraInfo.getHardwareVer().c_str()];
    [aboutArray addObject:hardwareVer];
    NSString *firmwareVer = [NSString stringWithFormat:@"FirmwareVer: %s", cameraInfo.getFirmwareVer().c_str()];
    [aboutArray addObject:firmwareVer];
    NSString *serialNumber = [NSString stringWithFormat:@"SerialNumber: %s", cameraInfo.getSerialNumber().c_str()];
    [aboutArray addObject:serialNumber];
    
    NSString *copyright = @"Copyright © 2017-2018 iCatchTech";
    [aboutArray addObject:copyright];

    SHSettingData *aboutData = [[SHSettingData alloc] init];
    aboutData.textLabel = NSLocalizedString(@"SETTING_ABOUT", @"");
    aboutData.detailType = SettingDetailTypeAbout;
    aboutData.detailData = aboutArray;
    
    return aboutData;
}

- (ICatchCameraVersion)retrieveCameraVersion {
    if (!_curResult) {
        SHGettingProperty *currentWB = [SHGettingProperty gettingPropertyWithControl:_shCameraObj.sdk.control];
        [currentWB addProperty:TRANS_PROP_CAMERA_VERSION];
        _curResult = [currentWB submit];
    }
    
    SHPropertyQueryResult *result =_curResult;
    
    string jsonStr = [result praseString2:TRANS_PROP_CAMERA_VERSION];
    SHLogInfo(SHLogTagAPP, @"retrieveCameraVersion: %s", jsonStr.c_str());
    
    ICatchCameraVersion cameraInfo;
    ICatchCameraVersion::parseString(jsonStr, cameraInfo);
    
    return cameraInfo;
}

@end
