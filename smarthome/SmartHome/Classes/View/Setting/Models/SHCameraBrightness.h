//
//  SHCameraBrightness.h
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHCameraBrightness : SHRangeItemData

//@property (nonatomic) ICatchWificamControl *control;

+ (instancetype)cameraBrightnessWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForCameraBrightness;
- (int)retrieveCurrentCameraBrightness;
- (SHRangeItem *)retrieveSupportedCameraBrightness;
- (BOOL)changeCameraBrightness:(int)newCameraBrightness;

@end
