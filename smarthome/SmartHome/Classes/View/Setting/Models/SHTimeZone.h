//
//  SHTimeZone.h
//  SmartHome
//
//  Created by ZJ on 2017/7/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHTimeZone : NSObject

@property (nonatomic, assign) float offset;
@property (nonatomic, assign) BOOL isdst;
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *locate;
@property (nonatomic, strong) NSString *detailCity;

@property (nonatomic, strong) NSMutableDictionary *timeZoneDict;
@property (nonatomic) SHPropertyQueryResult *curResult;

+ (instancetype)timeZoneWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareTimeZoneData;

@end
