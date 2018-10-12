//
//  SHSettingData.h
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHSettingData : NSObject

@property (nonatomic, copy) NSString *textLabel;
@property (nonatomic, copy) NSString *detailTextLabel;
@property (nonatomic, assign) SettingDetailType detailType;
@property (nonatomic, strong) NSArray *detailData;
@property (nonatomic, strong) NSArray *detailOriginalData;
@property (nonatomic, assign) NSInteger detailLastItem;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic, assign) int propertyID;
@property (nonatomic, copy) NSString *methodName;

+ (instancetype)settingDataWithTextLabel:(NSString *)textLabel andDetailTextLabel:(NSString *)detailTextLabel andDetailType:(SettingDetailType)detailType andDetailData:(NSArray *)detailData andDetailOriginalData:(NSArray *)detailOriginalData andDetailLastItem:(NSInteger)detailLastItem andUnit:(NSString *)unit andPropertyID:(int)propertyID;

@end
