//
//  SHNetworkManager+SHCamera.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHNetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const DEVICE_COVERS_PATH = @"v1/devices/covers";
static NSString * const DEVICE_UPGRADESINFO_PATH = @"v1/devices/upgrades/info";
static NSString * const DEVICE_MESSAGE_PATH = @"v1/devices/messages";

@interface SHNetworkManager (SHCamera)

- (void)bindCameraWithCameraUid:(NSString *)cameraUid name:(NSString *)cameraName password:(NSString *)password completion:(RequestCompletionBlock)completion;
- (void)unbindCameraWithCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion;

//获取相机及一些操作
- (void)getCameraByCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion;
- (void)getCameraByCameraUID:(NSString *)cameraUid completion:(RequestCompletionBlock)completion;
- (void)getCameraList:(RequestCompletionBlock)completion;
- (void)renameCameraByCameraID:(NSString *)cameraId andNewName:(NSString * _Nonnull)name completion:(RequestCompletionBlock)completion;
- (void)fixedAliasByCameraID:(NSString * _Nonnull)cameraId andAlias:(NSString * _Nonnull)alias completion:(RequestCompletionBlock)completion;
-(void)changeCameraPasswordByCameraID:(NSString * _Nonnull)cameraId andNewPassword:(NSString *_Nonnull)password completion:(RequestCompletionBlock)completion;

- (void)updateCameraCoverByCameraID:(NSString *)cameraId andCoverData:(NSData *)data completion:(RequestCompletionBlock)completion;
- (void)getCameraCoverByCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion;

- (void)checkDeviceHasExistsWithUID:(NSString *)uid completion:(RequestCompletionBlock)completion;

//分享相机
- (void)shareCameraWithCameraID:(NSString *)cameraId viaCode:(NSString * _Nonnull)viaCode duration:(long)duration userLimits:(char)user_limits completion:(RequestCompletionBlock)completion;
- (void)shareCameraWithCameraID:(NSString *)cameraId toUser:(NSString *)usreID permission:(char)permisssion duration:(long)duration completion:(RequestCompletionBlock)completion;

//订阅、取消
- (void)subscribeCameraWithCameraID:(NSString *)cameraId cameraName:(NSString *)cameraName invitationCode:(NSString * _Nullable)code completion:(RequestCompletionBlock)completion;
- (void)unsubscribeCameraWithCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion;
- (void)getCameraSubscribersWithCameraID:(NSString *)cameraId status:(int)status completion:(RequestCompletionBlock)completion;
- (void)removeCameraSubscriberWithCameraID:(NSString *)cameraId userID:(NSString *_Nonnull)userId completion:(RequestCompletionBlock)completion;

//- (void)getImgCoverWithFullURL:(NSString *)url completion:(RequestCompletionBlock)completion;
- (void)getDeviceUpgradesInfoWithCameraID:(NSString *)cameraID completion:(RequestCompletionBlock)completion;

- (void)getDeviceMessageWithDeviceID:(NSString *)deviceID sinceid:(NSNumber * _Nullable)sinceid enddate:(NSString * _Nullable)enddate completion:(RequestCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
