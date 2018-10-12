//
//  SHVideoSize.h
//  SmartHome
//
//  Created by ZJ on 2017/5/19.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHVideoSize : NSObject

//@property (nonatomic) ICatchWificamControl *control;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) SHPropertyQueryResult *supResult;

+ (instancetype)videoSizeWithCamera:(SHCameraObject *)cameraObj;
- (SHSettingData *)prepareDataForVideoSize;
- (NSString *)retrieveCurrentVideoSize;
- (NSArray *)retrieveSupportedVideoSize:(NSString *)curVideoSize;
- (BOOL)changeVideoSize:(NSString *)newVideoSize;

@end
