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

@property (nonatomic) BOOL isConnect;
@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) SHPropertyQueryResult *curResult;
@property (nonatomic) void (^cameraPropertyValueChangeBlock)(SHICatchEvent *evt);
@property (nonatomic) BOOL isEnterBackground;

@property (nonatomic, assign) BOOL startPV;
@property (nonatomic, assign) ICatchVideoQuality streamQuality;

+ (instancetype)cameraObjectWithCamera:(SHCamera *)camera;

//- (void)connectWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)disConnectWithSuccessBlock:(void(^)())successBlock failedBlock:(void(^)())failedBlock;
- (int)connectCamera;
- (void)updatePreviewThumbnailWithPvTime: (NSString *)tempPVTime;
- (void)initCamera;
- (void)openAudioServer;

@end
