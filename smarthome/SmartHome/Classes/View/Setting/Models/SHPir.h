//
//  SHPir.h
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHPir : SHRangeItemData

+ (instancetype)pirWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForPir;
- (int)retrieveCurrentPir;
- (SHRangeItem *)retrieveSupportedPir;
- (BOOL)changePir:(int)newPir;

@end
