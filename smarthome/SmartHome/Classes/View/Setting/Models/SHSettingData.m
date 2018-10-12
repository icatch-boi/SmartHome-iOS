//
//  SHSettingData.m
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSettingData.h"

@implementation SHSettingData

+ (instancetype)settingDataWithTextLabel:(NSString *)textLabel andDetailTextLabel:(NSString *)detailTextLabel andDetailType:(SettingDetailType)detailType andDetailData:(NSArray *)detailData andDetailOriginalData:(NSArray *)detailOriginalData andDetailLastItem:(NSInteger)detailLastItem andUnit:(NSString *)unit andPropertyID:(int)propertyID {
    SHSettingData *settingData = [[self alloc] init];
    
    settingData.textLabel = textLabel;
    settingData.detailTextLabel = detailTextLabel;
    settingData.detailType = detailType;
    settingData.detailData = detailData;
    settingData.detailOriginalData = detailOriginalData;
    settingData.detailLastItem = detailLastItem;
    settingData.unit = unit;
    settingData.propertyID = propertyID;
    
    return settingData;
}

@end
