//
//  CameraOperate.h
//  SHAccountManagementKit
//
//  Created by 江果 on 06/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Camera.h"
#import "Token.h"
#import "Error.h"
#import "Subscriber.h"
#import "CoverInfo.h"
#import "BasicDeviceInfo.h"
#import "BasicVisitInfo.h"

@interface CameraOperate : NSObject


-(void)bindCameraWithToken:(Token * _Nonnull)token
                   WithUid:(NSString *_Nonnull)uid
                   andName:(NSString *_Nonnull)name
               andPassword:(NSString *_Nullable)password
                   success:(void (^_Nullable)(Camera * _Nullable camera))success
                   failure:(void (^_Nullable)(Error * _Nonnull error))failure;

-(void)unbindCameraWithToken:(Token * _Nonnull)token
                WithCameraId:(NSString * _Nonnull)cameraId
                    success:(nullable void (^)(void))success
                    failure:(nullable void (^)(Error * _Nonnull error))failure;

-(void)getCameraByCameraId:(NSString * _Nonnull)cameraId
                 WithToken:(Token * _Nonnull)token
                   success:(nullable void (^)(Camera * _Nullable camera))success
                   failure:(nullable void (^)(Error * _Nonnull error))failure;

-(void)getCameraByCameraUID:(NSString * _Nonnull)cameraUID
                  WithToken:(Token * _Nonnull)token
                   success:(nullable void (^)(Camera * _Nullable camera))success
                   failure:(nullable void (^)(Error * _Nonnull error))failure;

-(void)getCamerasWithToken:(Token * _Nonnull)token
                   success:(nullable void (^)(NSArray <Camera *>* _Nullable cameras))success
                   failure:(nullable void (^)(Error* _Nonnull error))failure;

//修改相机名称
-(void)renameCameraByCameraId:(NSString * _Nonnull)cameraId
                    WithToken:(Token * _Nonnull)token
                   andNewName:(NSString * _Nonnull)name
                      success:(nullable void (^)(void))success
                      failure:(nullable void (^)(Error * _Nonnull error))failure;
//修改相机密码
-(void)changeCameraPasswordByCameraId:(NSString * _Nonnull)cameraId
                            WithToken:(Token * _Nonnull)token
                       andNewPassword:(NSString * _Nonnull)password
                              success:(nullable void (^)(void))success
                              failure:(nullable void (^)(Error * _Nonnull error))failure;

//修改相机别名
-(void)fixedAliasCameraId:(NSString * _Nonnull)cameraID
                WithToken:(Token * _Nonnull)token
                 andAlias:(NSString * _Nonnull)alias
                  success:(nullable void (^)(void))success
                  failure:(nullable void (^)(Error * _Nonnull error))failure;


//主动邀请--二维码 面对面扫码
-(void)shareCamera:(NSString * _Nonnull)cameraId
         WithToken:(Token * _Nonnull)token
     withShareCode:(NSString *_Nonnull)code
    withUserLimits:(int)count
    withPermission:(int)permission
  withCodeDuration:(int)duration
           success:(nullable void (^)(void))success
           failure:(nullable void (^)(Error * _Nonnull error))failure;

//主动邀请--设备拥有者邀请某人订阅相机
-(void)shareCamera:(NSString * _Nonnull)cameraId
         WithToken:(Token * _Nonnull)token
        withUserId:(NSString *_Nonnull)userId
    withPermission:(int)permission
  withCodeDuration:(int)duration
           success:(nullable void (^)(void))success
           failure:(nullable void (^)(Error * _Nonnull error))failure;

//某人通过二维码去主动订阅设备
-(void)subscribeCamera:(NSString * _Nonnull)cameraId
             WithToken:(Token * _Nonnull)token
         withShareCode:(NSString * _Nonnull)code
    withDeviceMemoName:(NSString * _Nullable)name
               success:(nullable void (^)(void))success
               failure:(nullable void (^)(Error * _Nonnull error))failure;

//某人订阅指定分享给某人的设备
-(void)subscribeCamera:(NSString * _Nonnull)cameraId
             WithToken:(Token * _Nonnull)token
    withDeviceMemoName:(NSString * _Nullable)name
               success:(nullable void (^)(void))success
               failure:(nullable void (^)(Error * _Nonnull error))failure;

//订阅者取消订阅相机
-(void)cancelSubscribeCamera:(NSString * _Nonnull)cameraId
                   WithToken:(Token * _Nonnull)token
           success:(nullable void (^)(void))success
           failure:(nullable void (^)(Error * _Nonnull error))failure;

//设备拥有者移除某人的订阅
-(void)removeSubscriberCamera:(NSString * _Nonnull)cameraId
                    WithToken:(Token * _Nonnull)token
             withSubscriberId:(NSString * _Nonnull)userId
                      success:(nullable void (^)(void))success
                      failure:(nullable void (^)(Error * _Nonnull error))failure;
//获取某设备的订阅者
-(void)getSubscribers:(NSString *_Nonnull)cameraId
            WithToken:(Token * _Nonnull)token
               status:(int)status
              success:(nullable void (^)(NSArray * _Nullable subscibers))success
              failure:(nullable void (^)(Error * _Nonnull error))failure;

//设备拥有者修改订阅者权限
-(void)fixSubscriberPermission:(NSString * _Nonnull)camera
                     WithToken:(Token * _Nonnull)token
                 andSubscriber:(NSString * _Nonnull)subscriberId
                 andPermission:(int)permission
                       success:(nullable void (^)(void))success
                       failure:(nullable void (^)(Error * _Nonnull error))failure;

//订阅者申请设备某个权限
-(void)subscriberBegPermission:(NSString * _Nonnull)CameraId
                     WithToken:(Token * _Nonnull)token
                withPermission:(int)permission
                       success:(nullable void (^)(void))success
                       failure:(nullable void (^)(Error * _Nonnull error))failure;

//上传设备封面
-(void)updateCoverWithToken:(Token *_Nonnull)token
                  andCamera:(NSString *)cameraId
               andCoverData:(NSData *_Nonnull)coverData
                    success:(nullable void (^)(CoverInfo* _Nonnull info))success
                    failure:(nullable void (^)(Error* _Nonnull error))failure;
//获取设备封面
-(void)getCoverWithToken:(Token *_Nonnull)token
               andCamera:(NSString *)cameraId
                 success:(nullable void (^)(CoverInfo* _Nonnull info))success
                 failure:(nullable void (^)(Error* _Nonnull error))failure;
//删除设备封面
-(void)deleteCoverWithToken:(Token *_Nonnull)token
                  andCamera:(NSString *)cameraId
                    success:(nullable void (^)(void))success
                    failure:(nullable void (^)(Error* _Nonnull error))failure;

//获取某个设备的拜访者的行为记录
-(void)getVisitorInfoWithDeviceId:(NSString * _Nonnull)deviceId
                        WithToken:(Token * _Nonnull)token
                  andSubscriberId:(NSString * _Nonnull)userId
                          success:(nullable void (^)(BasicVisitInfo* _Nonnull info))success
                          failure:(nullable void (^)(Error* _Nonnull error))failure;




@end
