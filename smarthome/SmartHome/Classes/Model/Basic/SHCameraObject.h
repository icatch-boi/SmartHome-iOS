//
//  SHCam.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHCameraProperty.h"
#import "SHPhotoGallery.h"
#import "SHControlCenter.h"
#import "SHStreamOperate.h"
#ifdef KUSE_S3_SERVICE
#import "SHDeviceAWSS3Helper.h"
#endif

typedef void(^UpdateNewMessageCountBlock)(void);

@class SHCamera;
@interface SHCameraObject : NSObject

// Camera
@property (nonatomic, strong) SHCamera *camera;
@property (nonatomic, strong) SHSDK *sdk;
// CameraProperty
@property (nonatomic, strong) SHCameraProperty *cameraProperty;
// Photo gallery
@property (nonatomic, strong) SHPhotoGallery *gallery;
// Controler
@property (nonatomic, strong) SHControlCenter *controler;

@property (nonatomic, strong) SHStreamOperate *streamOper;
@property (nonatomic, assign) NSInteger newFilesCount;
@property (nonatomic, assign, readonly) NSUInteger newMessageCount;
@property (nonatomic, copy) UpdateNewMessageCountBlock updateNewMessageCount;

@property (nonatomic) BOOL isConnect;
@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) void (^cameraPropertyValueChangeBlock)(SHICatchEvent *evt);
@property (nonatomic) BOOL isEnterBackground;

@property (nonatomic, assign) BOOL startPV;
@property (nonatomic, assign) ICatchVideoQuality streamQuality;

#ifdef KUSE_S3_SERVICE
@property (nonatomic, strong) SHDeviceAWSS3Helper *awsS3Helper;
#endif

+ (instancetype)cameraObjectWithCamera:(SHCamera *)camera;

- (void)disConnectWithSuccessBlock:(void(^)())successBlock failedBlock:(void(^)())failedBlock;
- (int)connectCamera;
- (void)updatePreviewThumbnailWithPvTime: (NSString *)tempPVTime;
- (void)initCamera;
- (void)openAudioServer;

#pragma mark - NewMessageCount Ops
- (void)incrementNewMessageCount;
- (void)incrementNewMessageCountBy:(NSUInteger)amount;
- (void)resetNewMessageCount;

@end
