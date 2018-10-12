//
//  SHSleepTime.m
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSleepTime.h"

@implementation SHSleepTime

+ (instancetype)sleepTimeWithCamera:(SHCameraObject *)cameraObj {
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_CAMERA_SLEEP_TIME];
}

- (SHSettingData *)prepareDataForSleepTime {
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_SLEEP_TIME", nil) andUnit:@"s" andSettingDetailType:SettingDetailTypeSleepTime];
}

- (int)retrieveCurrentSleepTime {
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedSleepTime {
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeSleepTime:(int)newSleepTime {
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newSleepTime];
}

@end
