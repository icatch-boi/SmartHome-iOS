//
//  SHActionControl.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SHCameraObject;
@class SHICatchEvent;
@interface SHActionControl : NSObject

@property (nonatomic, weak) SHCameraObject *shCamObj;
@property (nonatomic) void (^videoRecordingTimerBlock)();
@property (nonatomic) void (^updateVideoRecordTimerLabel)(NSDictionary *change);
@property (nonatomic) BOOL isRecord;
@property (nonatomic) void (^videoRecordBlock)(SHICatchEvent *evt);

- (void)startVideoRecWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)(int result))failedBlock noCardBlock:(void(^)())noCardBlock cardFullBlock:(void(^)())cardFullBlock;
- (void)stopVideoRecWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)stillCaptureWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock;

@end
