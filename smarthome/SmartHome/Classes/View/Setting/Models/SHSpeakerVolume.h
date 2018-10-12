//
//  SHSpeakerVolume.h
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHRangeItemData.h"

@interface SHSpeakerVolume : SHRangeItemData

+ (instancetype)speakerVolumeWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForSpeakerVolume;
- (int)retrieveCurrentSpeakerVolume;
- (SHRangeItem *)retrieveSupportedSpeakerVolume;
- (BOOL)changeSpeakerVolume:(int)newSpeakerVolume;

@end
