
// SHLocalWithRemoteHelper.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2018/4/27 上午11:35.
    

#import "SHLocalWithRemoteHelper.h"
#import "SHNetworkManagerHeader.h"

static NSString * const kInvalidDeviceName = @"NA";

@implementation SHLocalWithRemoteHelper

+ (void)checkDevicesStatus:(NSArray *)devices {
    [devices enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        Camera *camera = obj;
        
        [SHSDK checkDeviceStatusWithUID:camera.uid];
    }];
}

+ (void)syncCameraList:(SyncRemoteDataCompletionBlock)completion {
    WEAK_SELF(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SHNetworkManager sharedNetworkManager] getCameraList:^(BOOL isSuccess, id result) {
            SHLogInfo(SHLogTagAPP, @"get camera list is success: %d", isSuccess);
            
            if (isSuccess) {
  //              [[CoreDataHandler sharedCoreDataHander] deleteAllCameras];
                [[CoreDataHandler sharedCoreDataHander] updateLocalCamerasWithRemoteCameras:result];
                
#if 0
                // use device list2 api
                [weakself addCameras2LocalSqlite:result completion:completion];
#else
                [weakself getDeviceDetailInfoAndAdd2Local:result completion:completion];
#endif
//                [self checkDevicesStatus:result];
            } else {
                Error *error = result;
                SHLogError(SHLogTagAPP, @"getCameraList is faild: %@", error.error_description);
                
                if (completion) {
                    completion(isSuccess);
                }
            }
        }];
    });
}

+ (void)addCameras2LocalSqlite:(NSArray *)cameraList completion:(SyncRemoteDataCompletionBlock)completion {
    if (cameraList == nil) {
        SHLogError(SHLogTagSDK, @"cameraList is nil.");
        
        if (completion) {
            completion(NO);
        }
        
        return;
    }
    
    if (cameraList.count == 0) {
        if (completion) {
            completion(YES);
        }
    } else {
        [cameraList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Camera *info = obj;
            
            [self addCamera2LocalSqlite:info];
            
            if (idx == (cameraList.count - 1)) {
                if (completion) {
                    completion(YES);
                }
            }
        }];
    }
}

+ (void)addCamera2LocalSqlite:(Camera *)camera_server {
    __block UIImage *thumbnail = nil;

    int permission = 1;
    
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if (![camera_server.ownerId isEqualToString:owner]) {
        permission = 0;
    }
    
    SHLogInfo(SHLogTagAPP, @"own camera : %@, camera uid: %@", permission == 1 ? @"YES" : @"NO", camera_server.uid);

    NSString *name = camera_server.name;
    if (permission != 1) {
        name = camera_server.memoname;
        if([name compare:@"(null)"] == 0) {
            name = [camera_server.uid substringToIndex:5];
        }
    }
    
    [self getThumbnailWithName:name permission:permission camera:camera_server];

    SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:camera_server.uid devicePassword:camera_server.devicepassword id:camera_server.id thumbnail:thumbnail operable:permission];
    camera.addTime = [SHTool localDBTimeStringFromServer:camera_server.time];
    SHLogInfo(SHLogTagAPP, @"===> camera: %@", camera);
    
    [[CoreDataHandler sharedCoreDataHander] addCamera:camera];
    
}

// async get camera thumbnail
+ (void)getThumbnailWithName:(NSString *)name permission:(int)permission camera:(Camera *)camera_server {
    NSString *urlString = camera_server.cover;
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    
    if (urlString != nil && url != nil && request != nil) {
        NSDate *start = [NSDate date];
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDate *end = [NSDate date];
            SHLogInfo(SHLogTagAPP, @"Get thumbnail interval: %f.", [end timeIntervalSinceDate:start]);
            
            if (error == nil) {
                if (data != nil && data.length > 0) {
                    UIImage *thumbnail = [[UIImage alloc] initWithData:data];
                    
                    if (thumbnail != nil) {
                        SHLogInfo(SHLogTagAPP, @"Get thumbnail size: %lu.", data.length);
                        
                        SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:camera_server.uid devicePassword:camera_server.devicepassword id:camera_server.id thumbnail:thumbnail operable:permission];
                        [[CoreDataHandler sharedCoreDataHander] updateCameraThumbnail:camera];
                    } else {
                        SHLogError(SHLogTagAPP, @"Get thumbnail failed, data length: %lu.", data.length);
                    }
                } else {
                    SHLogError(SHLogTagAPP, @"Get thumbnail failed, data length: %lu.", data.length);
                }
            } else {
                SHLogError(SHLogTagAPP, @"Request failed, error: %@", error);
            }
        }] resume];
    } else {
        SHLogError(SHLogTagAPP, @"Get thumbnail failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
    }
}

+ (void)getDeviceDetailInfoAndAdd2Local:(NSArray *)cameraList completion:(SyncRemoteDataCompletionBlock)completion {
    if (cameraList == nil) {
        SHLogError(SHLogTagSDK, @"cameraList is nil.");
        
        if (completion) {
            completion(NO);
        }
        
        return;
    }
    
    if (cameraList.count == 0) {
        if (completion) {
            completion(YES);
        }
    } else {
#if 0
        __block BOOL success = YES;
        [cameraList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Camera *info = obj;

            [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:info.id completion:^(BOOL isSuccess, id  _Nullable result) {
                if (isSuccess == YES) {
                    [self addDevice2LocalWithBaseInfo:info deviceInfo:result];
                } else {
                    success = isSuccess;
                }
                
                if (idx == (cameraList.count - 1)) {
                    if (completion) {
                        completion(success);
                    }
                }
            }];
        }];
#else
        dispatch_group_t group = dispatch_group_create();
        dispatch_queue_t queue = dispatch_queue_create("com.icatchtek.GetDeviceDetailInfo", DISPATCH_QUEUE_CONCURRENT);
        
        __block BOOL success = NO;
        WEAK_SELF(self);
        [cameraList enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Camera *info = obj;
            
            if ([weakself checkDeviceIsValidWithCamera:info]) {
            
                dispatch_group_enter(group);
                dispatch_async(queue, ^{
                    [[SHNetworkManager sharedNetworkManager] getCameraByCameraID:info.id completion:^(BOOL isSuccess, id  _Nullable result) {
                        if (isSuccess) {
                            [weakself addDevice2LocalWithBaseInfo:info deviceInfo:result];
                            
                            success = isSuccess;
                        }
                        
                        dispatch_group_leave(group);
                    }];
                });
            } else {
                [weakself invalidDeviceHandleWithCamera:info];
            }
        }];
        
        dispatch_group_notify(group, queue, ^{
            if (completion) {
                completion(success);
            }
        });
#endif
    }
}

+ (void)invalidDeviceHandleWithCamera:(Camera *)camera {
    if (camera == nil) {
        SHLogWarn(SHLogTagAPP, @"Parameter `camera` is nil.");
        return;
    }
    
    int operable = 1;
    
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if (![camera.ownerId isEqualToString:owner]) {
        operable = 0;
    }
    
    if (operable == 1) {
        [[SHNetworkManager sharedNetworkManager] unbindCameraWithCameraID:camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"unbind invalid device [%@] is success: %d.", camera.name, isSuccess);
        }];
    } else {
        [[SHNetworkManager sharedNetworkManager] unsubscribeCameraWithCameraID:camera.id completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"unsubscribe invalid device [%@] is success: %d.", camera.name, isSuccess);
        }];
    }
}

+ (BOOL)checkDeviceIsValidWithCamera:(Camera *)camera {
    BOOL valid = YES;
    if ([camera.name isEqualToString:kInvalidDeviceName]) {
        valid = NO;
    }
    
    return valid;
}

+ (void)addDevice2LocalWithBaseInfo:(Camera *)baseInfo deviceInfo:(Camera *)deviceInfo {
    if (baseInfo == nil || deviceInfo == nil) {
        SHLogError(SHLogTagAPP, @"baseInfo or deviceInfo is nil, baseInfo: %@, deviceInfo: %@", baseInfo, deviceInfo);
        return;
    }
    
    int operable = 1;
    
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if (![deviceInfo.ownerId isEqualToString:owner]) {
        operable = 0;
    }
    
    SHLogInfo(SHLogTagAPP, @"Own camera: %@, camera uid: %@", operable == 1 ? @"YES" : @"NO", deviceInfo.uid);
    
    NSString *name = baseInfo.name;
    if (name == nil || name.length <= 0 || [name isEqualToString:@"(null)"]) {
        name = [deviceInfo.uid substringToIndex:5];
    }
    
//    [self getThumbnailWithName:name permission:permission camera:camera_server];

    SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:deviceInfo.uid devicePassword:deviceInfo.devicepassword id:deviceInfo.id thumbnail:nil operable:operable];
    camera.addTime = [SHTool localDBTimeStringFromServer:baseInfo.time];
    SHLogInfo(SHLogTagAPP, @"===> camera: %@", camera);
    
    [[CoreDataHandler sharedCoreDataHander] addCamera:camera];
    [self getThumbnailWithdeviceInfo:deviceInfo];
}

+ (void)getThumbnailWithdeviceInfo:(Camera *)deviceInfo {
#ifndef KUSE_S3_SERVICE
    [[SHNetworkManager sharedNetworkManager] getCameraCoverByCameraID:deviceInfo.id completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            [self downloadThumbnailWithURLString:result[@"url"] finised:^(UIImage *thumbnail) {
                if (thumbnail == nil) {
                    SHLogWarn(SHLogTagAPP, @"Obtained thumbnail is nil.");
                    return;
                }
                SHCameraHelper *camera = [[SHCameraHelper alloc] init];
                camera.cameraUid = deviceInfo.uid;
                camera.thumnail = thumbnail;
                
                [[CoreDataHandler sharedCoreDataHander] updateCameraThumbnail:camera];
            }];
        } else {
            SHLogError(SHLogTagAPP, @"Request failed, error: %@", result);
        }
    }];
#else
    [[SHENetworkManager sharedManager] getDeviceCoverWithDeviceID:deviceInfo.id completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"getDeviceCoverWithCompletion result: %@", result);

        if (isSuccess && result != nil) {
            SHCameraHelper *camera = [[SHCameraHelper alloc] init];
            camera.cameraUid = deviceInfo.uid;
            camera.thumnail = result;
            
            [[CoreDataHandler sharedCoreDataHander] updateCameraThumbnail:camera];
        }
    }];
#endif
}

+ (void)downloadThumbnailWithURLString:(NSString *)urlString finised:(void (^)(UIImage *thumbnail))finised {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIME_OUT_INTERVAL];
    
#if 0
    if (urlString != nil && url != nil && request != nil) {
        NSDate *start = [NSDate date];
        
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSDate *end = [NSDate date];
            SHLogInfo(SHLogTagAPP, @"Get thumbnail interval: %f.", [end timeIntervalSinceDate:start]);
            
            if (error == nil) {
                if (data != nil && data.length > 0) {
                    UIImage *thumbnail = [[UIImage alloc] initWithData:data];
                    
                    if (thumbnail != nil) {
                        SHLogInfo(SHLogTagAPP, @"Get thumbnail size: %lu.", data.length);
                        
                        if (finised) {
                            finised(thumbnail);
                        }
                    } else {
                        SHLogError(SHLogTagAPP, @"Get thumbnail failed, data length: %lu.", data.length);
                    }
                } else {
                    SHLogError(SHLogTagAPP, @"Get thumbnail failed, data length: %lu.", data.length);
                }
            } else {
                SHLogError(SHLogTagAPP, @"Request failed, error: %@", error);
            }
        }] resume];
    } else {
        SHLogError(SHLogTagAPP, @"Get thumbnail failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
    }
#else
    if (urlString == nil || url == nil || request == nil) {
        SHLogError(SHLogTagAPP, @"Get thumbnail failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
        
        if (finised) {
            finised(nil);
        }
        
        return;
    }
    
    NSDate *start = [NSDate date];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDate *end = [NSDate date];
        SHLogInfo(SHLogTagAPP, @"Get thumbnail interval: %f.", [end timeIntervalSinceDate:start]);
        
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
            
            if (finised) {
                finised(nil);
            }
            
            return;
        }
        
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)response;
        
        if (respose.statusCode == 200 || respose.statusCode == 304) {
            SHLogInfo(SHLogTagAPP, @"Get thumbnail size: %lu.", (unsigned long)data.length);

            if (finised) {
                finised([[UIImage alloc] initWithData:data]);
            }
        } else {
            SHLogError(SHLogTagAPP, @"服务器内部错误，statusCode: %d", respose.statusCode);
            
            if (finised) {
                finised(nil);
            }
        }
    }] resume];
#endif
}

@end
