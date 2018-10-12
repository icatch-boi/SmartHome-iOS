//
//  SHSpeakerVolume.m
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSpeakerVolume.h"

@implementation SHSpeakerVolume

+ (instancetype)speakerVolumeWithCamera:(SHCameraObject *)cameraObj {
    return [super rangeItemDataWithCamera:cameraObj andPropertyID:TRANS_PROP_CAMERA_SPEAKER_VOLUME];
}

- (SHSettingData *)prepareDataForSpeakerVolume {
    return [super prepareDataForRangeItemWithPropertyID:0 andTitle:NSLocalizedString(@"SETTING_SPEAKER_VOLUME", nil) andUnit:@"%" andSettingDetailType:SettingDetailTypeSpeakerVolume];
}

- (int)retrieveCurrentSpeakerVolume {
    return [super retrieveRangeItemCurrentValueWithPropertyID:0];
}

- (SHRangeItem *)retrieveSupportedSpeakerVolume {
    return [super retrieveRangeItemSupportedValueWithPropertyID:0];
}

- (BOOL)changeSpeakerVolume:(int)newSpeakerVolume {
    return [super changeRangeItemValueWithPropertyID:0 andNewValue:newSpeakerVolume];
}

@end
