//
//  SHLightFrequency.h
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHLightFrequency : NSObject

//@property (nonatomic) ICatchWificamControl *control;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) SHPropertyQueryResult *supResult;

+ (instancetype)lightFrequencyWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForLightFrequency;
- (int)retrieveCurrentLightFrequency;
- (NSArray *)retrieveSupportedLightFrequency:(int)curLightFrequency;
- (BOOL)changeLightFrequency:(int)newLightFrequency;

@end
