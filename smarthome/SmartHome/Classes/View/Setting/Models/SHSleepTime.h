//
//  SHSleepTime.h
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHRangeItemData.h"

@interface SHSleepTime : SHRangeItemData

+ (instancetype)sleepTimeWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForSleepTime;
- (int)retrieveCurrentSleepTime;
- (SHRangeItem *)retrieveSupportedSleepTime;
- (BOOL)changeSleepTime:(int)newSleepTime;

@end
