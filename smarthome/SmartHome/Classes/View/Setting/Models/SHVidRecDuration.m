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
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_DET_VID_REC_DURATION];
}

- (SHSettingData *)prepareDataForVidRecDuration {
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_VID_REC_DURATION", @"") andUnit:@"s" andSettingDetailType:SettingDetailTypeVidRecDuration];
}

- (int)retrieveCurrentVidRecDuration {
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedVidRecDuration {
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeVidRecDuration:(int)newVidRecDuration {
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newVidRecDuration];
}

@end
