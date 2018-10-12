//
//  SHWhiteBalance.h
//  SmartHome
//
//  Created by ZJ on 2017/5/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SHomeCamera;
@class SHCameraObject;
@interface SHWhiteBalance : NSObject

//@property (nonatomic) ICatchWificamControl *control;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) SHPropertyQueryResult *supResult;

+ (instancetype)whiteBalanceWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForWhiteBalance;
- (int)retrieveCurrentWhiteBalance;
- (NSArray *)retrieveSupportedWhiteBalance:(int)curWhiteBalance;
- (BOOL)changeWhiteBalance:(int)newWhiteBalance;

@end
