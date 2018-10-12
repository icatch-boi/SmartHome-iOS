//
//  SHRangeItemManger.h
//  SmartHome
//
//  Created by ZJ on 2017/5/22.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHRangeItemData : NSObject

@property (nonatomic, assign) int propertyID;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) SHPropertyQueryResult *rangeResult;

+ (instancetype)rangeItemDataWithCamera:(SHCameraObject *)cameraObj andPropertyID:(int)propertyID;
- (SHSettingData *)prepareDataForRangeItemWithPropertyID:(int)propertyID andTitle:(NSString *)title andUnit:(NSString *)unit andSettingDetailType:(SettingDetailType)type;
- (int)retrieveRangeItemCurrentValueWithPropertyID:(int)propertyID;
- (SHRangeItem *)retrieveRangeItemSupportedValueWithPropertyID:(int)propertyID;
- (BOOL)changeRangeItemValueWithPropertyID:(int)propertyID andNewValue:(int)newValue;

@end
