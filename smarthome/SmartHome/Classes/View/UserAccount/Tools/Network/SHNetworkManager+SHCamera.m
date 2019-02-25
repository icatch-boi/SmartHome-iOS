//
//  SHNetworkManager+SHCamera.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHNetworkManager+SHCamera.h"
#import <SHAccountManagementKit/CameraOperate.h>
#import "SHUserAccount.h"
#import "ZJRequestError.h"
#import <AFNetworking/AFNetworking.h>

@implementation SHNetworkManager (SHCamera)

- (Token *)createToken {
    return [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token,
                                         @"refresh_token" : self.userAccount.refresh_token,
                                         }];
}

- (void)bindCameraWithCameraUid:(NSString *)cameraUid name:(NSString *)cameraName password:(NSString *)password completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate bindCameraWithToken:[self createToken] WithUid:cameraUid andName:cameraName andPassword:password success:^(Camera * _Nullable camera) {
            if (completion) {
                completion(YES, camera);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"bindCameraWithCameraUid failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate bindCameraWithToken:[self createToken] WithUid:cameraUid andName:cameraName andPassword:password success:^(Camera * _Nullable camera) {
                    if (completion) {
                        completion(YES, camera);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"bindCameraWithCameraUid failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)unbindCameraWithCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate unbindCameraWithToken:[self createToken] WithCameraId:cameraId success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"unbindCameraWithCameraID failed, error: %@", error.error_description);
            
            // When device not exist, unbind operation invalid.
            if (error.error_code == 50002) {
                if (completion) {
                    completion(YES, error);
                }
                
                return;
            }
            
            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate unbindCameraWithToken:[self createToken] WithCameraId:cameraId success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"unbindCameraWithCameraID failed, error: %@", error.error_description);

                    // When device not exist, unbind operation invalid.
                    if (error.error_code == 50002) {
                        if (completion) {
                            completion(YES, error);
                        }
                        
                        return;
                    }
                    
                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)getCameraByCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate getCameraByCameraId:cameraId WithToken:[self createToken] success:^(Camera * _Nullable camera) {
            if (completion) {
                completion(YES, camera);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getCameraByCameraID failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate getCameraByCameraId:cameraId WithToken:[self createToken] success:^(Camera * _Nullable camera) {
                    if (completion) {
                        completion(YES, camera);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getCameraByCameraID failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)getCameraByCameraUID:(NSString *)cameraUid completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate getCameraByCameraUID:cameraUid WithToken:[self createToken] success:^(Camera * _Nullable camera) {
            if (completion) {
                completion(YES, camera);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getCameraByCameraUID failed, error: %@", error.error_description);
            
            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate getCameraByCameraUID:cameraUid WithToken:[self createToken] success:^(Camera * _Nullable camera) {
                    if (completion) {
                        completion(YES, camera);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getCameraByCameraUID failed, error: %@", error.error_description);
                    
                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)checkDeviceHasExistsWithUID:(NSString *)uid completion:(RequestCompletionBlock)completion {
    if (uid == nil || uid.length <= 0) {
        completion(NO, @"uid is nil.");
        return;
    }
    
    [self getCameraByCameraUID:uid completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            completion(isSuccess, @1);
        } else {
            NSNumber *value = @0;
            
            Error *err = result;
            if (err.error_code == 50001) {
                value = @1;
            }
            
            completion(YES, value);
        }
    }];
}

- (void)getCameraList:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate getCamerasWithToken:[self createToken] success:^(NSArray * _Nullable cameras) {
            if (completion) {
                completion(YES, cameras);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getCameraList failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate getCamerasWithToken:[self createToken] success:^(NSArray * _Nullable cameras) {
                    if (completion) {
                        completion(YES, cameras);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getCameraList failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)renameCameraByCameraID:(NSString *)cameraId andNewName:(NSString *)name completion:(RequestCompletionBlock)completion
{
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate renameCameraByCameraId:cameraId WithToken:[self createToken] andNewName:name success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"renameCameraByCameraID failed, error: %@", error.error_description);

            completion(NO, error);
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate renameCameraByCameraId:cameraId WithToken:[self createToken] andNewName:name success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"renameCameraByCameraID failed, error: %@", error.error_description);

                    completion(NO, error);
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}
- (void)fixedAliasByCameraID:(NSString *)cameraId andAlias:(NSString *)alias completion:(RequestCompletionBlock)completion
{
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate fixedAliasCameraId:cameraId WithToken:[self createToken] andAlias:alias success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"fixedAliasByCameraID failed, error: %@", error.error_description);

            completion(NO, error);
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate fixedAliasCameraId:cameraId WithToken:[self createToken] andAlias:alias success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"fixedAliasByCameraID failed, error: %@", error.error_description);

                    completion(NO, error);
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}
- (void)changeCameraPasswordByCameraID:(NSString *)cameraId andNewPassword:(NSString *)password completion:(RequestCompletionBlock)completion
{
    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate changeCameraPasswordByCameraId:cameraId WithToken:[self createToken] andNewPassword:password success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"changeCameraPasswordByCameraID failed, error: %@", error.error_description);

            completion(NO, error);
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate changeCameraPasswordByCameraId:cameraId WithToken:[self createToken] andNewPassword:password success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"changeCameraPasswordByCameraID failed, error: %@", error.error_description);

                    completion(NO, error);
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)updateCameraCoverByCameraID:(NSString *)cameraId andCoverData:(NSData *)data completion:(RequestCompletionBlock)completion
{
    if (self.userAccount.access_tokenHasEffective) {
#if 0
        [self.cameraOperate updateCoverWithToken:[self createToken] andCamera:cameraId andCoverData:data success:^(CoverInfo * _Nonnull info) {
            if(completion) {
                completion(YES, info);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"updateCameraCoverByCameraID failed, error: %@", error.error_description);

             completion(NO, error);
        }];
#else
        [self uploadDeviceCoverWithCameraID:cameraId data:data completion:completion];
#endif
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
#if 0
                [self.cameraOperate updateCoverWithToken:[self createToken] andCamera:cameraId andCoverData:data success:^(CoverInfo * _Nonnull info) {
                    if(completion) {
                        completion(YES, info);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"updateCameraCoverByCameraID failed, error: %@", error.error_description);

                    completion(NO, error);
                }];
#else
                [self uploadDeviceCoverWithCameraID:cameraId data:data completion:completion];
#endif
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)getCameraCoverByCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self getDeviceCoverWithCameraID:cameraId completion:completion];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self getDeviceCoverWithCameraID:cameraId completion:completion];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)shareCameraWithCameraID:(NSString *)cameraId viaCode:(NSString * _Nonnull)viaCode duration:(long)duration userLimits:(char)user_limits completion:(RequestCompletionBlock)completion {
    Camera *camera = [[Camera alloc] initWithData:@{@"id" : cameraId}];
    
    if (self.userAccount.access_tokenHasEffective) {
        if (viaCode != nil && user_limits != 0) {
            [self.cameraOperate shareCamera:camera.id WithToken:[self createToken] withShareCode:viaCode withUserLimits:user_limits withPermission:0 withCodeDuration:(int)duration success:^{
                if (completion) {
                    completion(YES, nil);
                }
            } failure:^(Error * _Nonnull error) {
                SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

                if (completion) {
                    completion(NO, error);
                }
            }];
        } else if (viaCode != nil) {
            [self.cameraOperate shareCamera:camera.id WithToken:[self createToken] withShareCode:viaCode withUserLimits:10 withPermission:0 withCodeDuration:(int)duration success:^{
                if (completion) {
                    completion(YES, nil);
                }
            } failure:^(Error * _Nonnull error) {
                SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

                if (completion) {
                    completion(NO, error);
                }
            }];
        }
        /*else {
            [self.cameraOperate shareCamera:camera withDuration:duration success:^(NSString * _Nullable code) {
                completion(YES, code);
            } failure:^(Error * _Nonnull error) {
                completion(NO, error);
            }];
        }*/
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                if (viaCode != nil && user_limits != 0) {
                    [self.cameraOperate shareCamera:camera.id WithToken:[self createToken] withShareCode:viaCode withUserLimits:user_limits withPermission:0 withCodeDuration:(int)duration success:^{
                        if (completion) {
                            completion(YES, nil);
                        }
                    } failure:^(Error * _Nonnull error) {
                        SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

                        if (completion) {
                            completion(NO, error);
                        }
                    }];
                } else if (viaCode != nil) {
                    [self.cameraOperate shareCamera:camera.id WithToken:[self createToken] withShareCode:viaCode withUserLimits:10 withPermission:0 withCodeDuration:(int)duration success:^{
                        if (completion) {
                            completion(YES, nil);
                        }
                    } failure:^(Error * _Nonnull error) {
                        SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

                        if (completion) {
                            completion(NO, error);
                        }
                    }];
                }
                /*else {
                 [self.cameraOperate shareCamera:camera withDuration:duration success:^(NSString * _Nullable code) {
                 completion(YES, code);
                 } failure:^(Error * _Nonnull error) {
                 completion(NO, error);
                 }];
                 }*/
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)shareCameraWithCameraID:(NSString *)cameraId toUser:(NSString *)usreID permission:(char)permisssion duration:(long)duration completion:(RequestCompletionBlock)completion {
//    Camera *camera = [[Camera alloc] initWithData:@{@"id" : cameraId}];

    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate shareCamera:cameraId WithToken:[self createToken] withUserId:usreID withPermission:permisssion withCodeDuration:(int)duration success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate shareCamera:cameraId WithToken:[self createToken] withUserId:usreID withPermission:permisssion withCodeDuration:(int)duration success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"shareCameraWithCameraID failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)subscribeCameraWithCameraID:(NSString *)cameraId cameraName:(NSString *)cameraName invitationCode:(NSString * _Nullable)code completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        if (code != nil) {
            
            [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withShareCode:code withDeviceMemoName:cameraName success:^{
                if (completion) {
                    completion(YES, nil);
                }
            } failure:^(Error * _Nonnull error) {
                SHLogError(SHLogTagSDK, @"subscribeCameraWithCameraID failed, error: %@", error.error_description);

                if (completion) {
                    completion(NO, error);
                }
            }];
        } else {
            [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withDeviceMemoName:cameraName success:^{
                if (completion) {
                    completion(YES, nil);
                }
            } failure:^(Error * _Nonnull error) {
                SHLogError(SHLogTagSDK, @"subscribeCameraWithCameraID failed, error: %@", error.error_description);

                if (completion) {
                    completion(NO, error);
                }
            }];
        }
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                if (code != nil) {
                    [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withShareCode:code withDeviceMemoName:cameraName success:^{
                        if (completion) {
                            completion(YES, nil);
                        }
                    } failure:^(Error * _Nonnull error) {
                        SHLogError(SHLogTagSDK, @"subscribeCameraWithCameraID failed, error: %@", error.error_description);

                        if (completion) {
                            completion(NO, error);
                        }
                    }];
                } else {
                    [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withDeviceMemoName:cameraName success:^{
                        if (completion) {
                            completion(YES, nil);
                        }
                    } failure:^(Error * _Nonnull error) {
                        SHLogError(SHLogTagSDK, @"subscribeCameraWithCameraID failed, error: %@", error.error_description);

                        if (completion) {
                            completion(NO, error);
                        }
                    }];
                }
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)unsubscribeCameraWithCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion {
    //Camera *camera = [[Camera alloc] initWithData:@{@"id" : cameraId}];

    if (self.userAccount.access_tokenHasEffective) {
        
        [self.cameraOperate cancelSubscribeCamera:cameraId WithToken:[self createToken] success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"unsubscribeCameraWithCameraID failed, error: %@", error.error_description);

            // When device not exist, unsubscribe operation invalid.
            if (error.error_code == 50002) {
                if (completion) {
                    completion(YES, error);
                }
                
                return;
            }
            
            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate cancelSubscribeCamera:cameraId WithToken:[self createToken] success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"unsubscribeCameraWithCameraID failed, error: %@", error.error_description);

                    // When device not exist, unsubscribe operation invalid.
                    if (error.error_code == 50002) {
                        if (completion) {
                            completion(YES, error);
                        }
                        
                        return;
                    }
                    
                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)getCameraSubscribersWithCameraID:(NSString *)cameraId status:(int)status completion:(RequestCompletionBlock)completion {
    Camera *camera = [[Camera alloc] initWithData:@{@"id" : cameraId}];

    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate getSubscribers:camera.id WithToken:[self createToken] status:status success:^(NSArray * _Nullable subscibers) {
            if (completion) {
                completion(YES, subscibers);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getCameraSubscribersWithCameraID failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate getSubscribers:camera.id WithToken:[self createToken] status:status success:^(NSArray * _Nullable subscibers) {
                    if (completion) {
                        completion(YES, subscibers);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getCameraSubscribersWithCameraID failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

- (void)removeCameraSubscriberWithCameraID:(NSString *)cameraId userID:(NSString *_Nonnull)userId completion:(RequestCompletionBlock)completion {
   // Camera *camera = [[Camera alloc] initWithData:@{@"id" : cameraId}];

    if (self.userAccount.access_tokenHasEffective) {
        [self.cameraOperate removeSubscriberCamera:cameraId WithToken:[self createToken] withSubscriberId:userId success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"removeCameraSubscriberWithCameraID failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate removeSubscriberCamera:cameraId WithToken:[self createToken] withSubscriberId:userId success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"removeCameraSubscriberWithCameraID failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            } else {
                if (completion) {
                    completion(NO, result);
                }
            }
        }];
    }
}

#pragma mark - Device Cover Handle
- (void)getDeviceCoverWithCameraID:(NSString *)cameraId completion:(RequestCompletionBlock)completion {
    if (cameraId == nil) {
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description": @"This parameter must not be `nil`.",
                                   };
            completion(NO, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    NSString *urlString = [self requestURLString:DEVICE_COVERS_PATH];
    
    NSDictionary *parametes = @{
                                @"id": cameraId,
                                };
    [self requestWithMethod:SHRequestMethodGET manager:nil urlString:urlString parametes:parametes finished:completion];
}

- (void)uploadDeviceCoverWithCameraID:(NSString *)cameraId data:(NSData *)data completion:(RequestCompletionBlock)completion {
    if (data == nil || data.length == 0 || cameraId == nil) {
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description": @"These parameter must not be `nil`.",
                                   };
            completion(NO, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    NSMutableURLRequest *request = [self deviceCoverRequestWithMethod:@"POST"];
    
    [request setValue:cameraId forHTTPHeaderField:@"deviceid"];
    
    NSString *len = [NSString stringWithFormat:@"%d", (int)data.length];
    SHLogInfo(SHLogTagAPP, @"Upload data length : %@", len);
    [request setValue:len forHTTPHeaderField:@"Content-Length"];
    
    // 设置body
    [request setHTTPBody:data];
    
    [self dataTaskWithRequest:request completion:completion];
}

- (NSMutableURLRequest *)deviceCoverRequestWithMethod:(NSString *)method {
    method = method ? method : @"POST";
    NSString *urlString = [self requestURLString:DEVICE_COVERS_PATH];

    NSMutableURLRequest *request = [[AFHTTPRequestSerializer serializer] requestWithMethod:method URLString:urlString parameters:nil error:nil];
    request.timeoutInterval = TIME_OUT_INTERVAL;
    
    [request setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
    
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token];
    [request setValue:token forHTTPHeaderField:@"Authorization"];

    return request;
}

- (void)dataTaskWithRequest:(NSURLRequest *)request completion:(RequestCompletionBlock)completion {
    if (request == nil) {
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description": @"This parameter must not be `nil`.",
                                   };
            completion(NO, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];

    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error == nil) {
            if (completion) {
                completion(YES, responseObject);
            }
        } else {
            NSHTTPURLResponse *respose = (NSHTTPURLResponse *)response;
            
            if (respose.statusCode == 403) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:error];
            }
            
            ZJRequestError *err = [ZJRequestError requestErrorWithNSError:error];
            SHLogError(SHLogTagAPP, @"网络请求错误: %@", err);
            
            if (completion) {
                completion(NO, err);
            }
        }
    }] resume];
}

#pragma mark - Request method
- (void)requestWithMethod:(SHRequestMethod)method manager:(AFHTTPSessionManager *)manager urlString:(NSString *)urlString parametes:(id)parametes finished:(RequestCompletionBlock)finished {
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (finished) {
            finished(YES, responseObject);
        }
    };
    
    id failure = ^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 403) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:error];
        }
        
        ZJRequestError *err = [ZJRequestError requestErrorWithNSError:error];
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", err);
        
        if (finished) {
            finished(NO, err);
        }
    };
    
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [self requestURLString:urlString];
    }
    
    if ([urlString hasPrefix:@"https:"] || [manager.baseURL.absoluteString hasPrefix:@"https:"]) {
        //设置 https 请求证书
        [self setCertificatesWithManager:manager];
    }
    
    if (manager == nil) {
        manager = [self defaultRequestSessionManager];
    }
    
    switch (method) {
        case SHRequestMethodGET:
            [manager GET:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPOST:
            [manager POST:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPUT:
            [manager PUT:urlString parameters:parametes success:success failure:failure];
            break;
            
        case SHRequestMethodDELETE:
            [manager DELETE:urlString parameters:parametes success:success failure:failure];
            break;
            
        default:
            break;
    }
}

- (NSString *)requestURLString:(NSString *)urlString {
    return [ServerBaseUrl stringByAppendingString:urlString];
}

- (AFHTTPSessionManager *)defaultRequestSessionManager {
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    return manager;
}

#pragma mark - Error Handle
- (ZJRequestError *)createErrorWithCode:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict {
    return [ZJRequestError requestErrorWithDict:dict];
}

#pragma mark - Certificate Handle
- (BOOL)setCertificatesWithManager:(AFURLSessionManager *)manager {
    if ([ServerUrl sharedServerUrl].useSSL) { //使用自制证书
        // /先导入证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"icatchtek" ofType:@"cer"];//证书的路径
        NSData *certData = [NSData dataWithContentsOfFile:cerPath];
        
        // AFSSLPinningModeCertificate 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        
        // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
        // 如果是需要验证自建证书，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        
        //validatesDomainName 是否需要验证域名，默认为YES；
        //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
        //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
        //如置为NO，建议自己添加对应域名的校验逻辑。
        securityPolicy.validatesDomainName = NO;
        NSSet <NSData *>* pinnedCertificates = [NSSet setWithObject:certData];
        
        //securityPolicy.pinnedCertificates = @[certData];
        securityPolicy.pinnedCertificates = pinnedCertificates;
        [manager setSecurityPolicy:securityPolicy];
    }
    
    return YES;
}

@end
