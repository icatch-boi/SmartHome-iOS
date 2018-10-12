//
//  SHMICVolume.h
//  SmartHome
//
//  Created by ZJ on 2017/5/23.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHRangeItemData.h"

@interface SHMICVolume : SHRangeItemData

+ (instancetype)micVolumeWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForMICVolume;
- (int)retrieveCurrentMICVolume;
- (SHRangeItem *)retrieveSupportedMICVolume;
- (BOOL)changeMICVolume:(int)newMICVolume;

@end
