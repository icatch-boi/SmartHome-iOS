//
//  SHAbout.h
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHAbout : NSObject

//@property (nonatomic) ICatchWificamControl *control;
@property (nonatomic) SHPropertyQueryResult *curResult;

+ (instancetype)aboutWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForAbout;

@end
