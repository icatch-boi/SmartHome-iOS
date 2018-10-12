//
//  SHMICVolume.m
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHMICVolume.h"

@implementation SHMICVolume

+ (instancetype)micVolumeWithCamera:(SHCameraObject *)cameraObj {
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_CAMERA_MIC_VOLUME];
}

- (SHSettingData *)prepareDataForMICVolume {
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_MIC_VOLUME", nil) andUnit:@"%" andSettingDetailType:SettingDetailTypeMICVolume];
}

- (int)retrieveCurrentMICVolume {
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedMICVolume {
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeMICVolume:(int)newMICVolume {
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newMICVolume];
}

@end
