//
//  SHCameraObjectControl.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHSaveSupportedProperty.h"

@interface SHPropertyControl : NSObject

@property (nonatomic, strong) SHSaveSupportedProperty *ssp;

- (SHPropertyQueryResult *)retrieveSettingCurPropertyWithCamera:(SHCameraObject *)shCameraObj;
- (SHPropertyQueryResult *)retrievePVCurPropertyWithCamera:(SHCameraObject *)shCameraObj;
- (SHPropertyQueryResult *)retrieveSettingSupPropertyWithCamera:(SHCameraObject *)shCameraObj;
- (BOOL)factoryResetWithCamera:(SHCameraObject *)shCameraObj;
- (NSData *)requestThumbnail:(ICatchFile *)file andPropertyID:(int)propertyID andCamera:(SHCameraObject *)shCameraObj;

- (uint)prepareDataForBatteryLevelWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult;
- (int)prepareDataForChargeStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult;
- (NSString *)transBatteryLevel2NStr:(unsigned int)value;
- (NSString *)prepareDataForPirStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult;
- (NSString *)transPirStatus2NStr:(unsigned int)value;
- (NSString *)prepareDataForSDCardStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult;
- (NSString *)transSDCardStatus2NStr:(int)value;
- (NSString *)prepareDataForWifiStatusWithCamera:(SHCameraObject *)shCameraObj andCurResult:(SHPropertyQueryResult *)curResult;
- (NSString *)transWifiStatus2NStr:(unsigned int)value;

- (int)retrieveSDCardFreeSpaceSizeWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (BOOL)checkSDExistWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (BOOL)checkSDFullWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (void)updateSDCardFreeSpaceSizeWithCamera:(SHCameraObject *)shCameraObj;

- (NSString *)retrieveLastPreviewTimeWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (UIImage *)retrievePreviewThumbanilWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;

- (ICatchCameraVersion)retrieveCameraVersionWithCamera:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (BOOL)compareFWVersion:(SHCameraObject *)shCameraObj curResult:(SHPropertyQueryResult *)curResult;
- (uint)retrieveNewFilesCountWithCamera:(SHCameraObject *)shCameraObj pbTime:(NSString *)pbTime;

- (shared_ptr<ICatchCameraVersion>)retrieveCameraVersionWithCamera:(SHCameraObject *)shCameraObj;

@end
