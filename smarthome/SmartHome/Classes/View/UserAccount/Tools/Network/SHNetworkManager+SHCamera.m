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
        [self.cameraOperate updateCoverWithToken:[self createToken] andCamera:cameraId andCoverData:data success:^(CoverInfo * _Nonnull info) {
            if(completion) {
                completion(YES, info);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"updateCameraCoverByCameraID failed, error: %@", error.error_description);

             completion(NO, error);
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
            if (isSuccess) {
                [self.cameraOperate updateCoverWithToken:[self createToken] andCamera:cameraId andCoverData:data success:^(CoverInfo * _Nonnull info) {
                    if(completion) {
                        completion(YES, info);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"updateCameraCoverByCameraID failed, error: %@", error.error_description);

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

- (void)subscribeCameraWithCameraID:(NSString *)cameraId invitationCode:(NSString * _Nullable)code completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        if (code != nil) {
            
            [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withShareCode:code withDeviceMemoName:nil success:^{
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
            [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withDeviceMemoName:nil success:^{
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
                    [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withShareCode:code withDeviceMemoName:@"devicexx" success:^{
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
                    [self.cameraOperate subscribeCamera:cameraId WithToken:[self createToken] withDeviceMemoName:@"device xx" success:^{
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
//- (void)getImgCoverWithFullURL:(NSString *)url completion:(RequestCompletionBlock)completion
//{
//    [self.cameraOperate getImgDataWithUrl:url success:^(NSURL * _Nonnull path) {
//        if(completion) {
//            completion(YES, path);
//        }
//    } failure:^(Error * _Nonnull error) {
//        if(completion) {
//            completion(NO, nil);
//        }
//    }];
//    
//}
@end
