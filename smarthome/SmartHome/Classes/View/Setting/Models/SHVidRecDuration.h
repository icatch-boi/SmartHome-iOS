//
//  SHVidRecDuration.h
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHVidRecDuration : SHRangeItemData

//@property (nonatomic) ICatchWificamControl *control;

+ (instancetype)vidRecDurationWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForVidRecDuration;
- (int)retrieveCurrentVidRecDuration;
- (SHRangeItem *)retrieveSupportedVidRecDuration;
- (BOOL)changeVidRecDuration:(int)newVidRecDuration;

@end
