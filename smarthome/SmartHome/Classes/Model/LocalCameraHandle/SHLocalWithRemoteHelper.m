
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
                
                [weakself addCameras2LocalSqlite:result completion:completion];
                [self checkDevicesStatus:result];
            } else {
                Error *error = result;
                NSLog(@"getCameraList is faild: %@", error.error_description);
                
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

#if 0
    int permission = -1;
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if ([camera_server.ownerId compare:owner] != 0) {
        permission = camera_server.operable;
    }
    
    NSLog(@"own camera : %@ operable = %d", permission == -1 ? @"YES" : @"NO", permission);
    NSString *name = camera_server.name;
    if (permission != -1 ) {
        name = camera_server.memoname;
        if([name compare:@"(null)"] == 0) {
            name = [camera_server.uid substringToIndex:5];
        }
    }
#else
    int permission = 1;
    
    NSString *owner = [SHNetworkManager sharedNetworkManager].userAccount.id;
    if (![camera_server.ownerId isEqualToString:owner]) {
        permission = 0;
    }
    
    NSLog(@"own camera : %@ operable = %d", permission == 1 ? @"YES" : @"NO", permission);

    NSString *name = camera_server.name;
    if (permission != 1) {
        name = camera_server.memoname;
        if([name compare:@"(null)"] == 0) {
            name = [camera_server.uid substringToIndex:5];
        }
    }
#endif
    
#if 0
    NSString *urlString = camera_server.cover;
    if (urlString != nil) {
        NSDate *start = [NSDate date];
        NSURL *url = [[NSURL alloc] initWithString:urlString];
        NSData *data = [[NSData alloc] initWithContentsOfURL:url];
        if (data.length > 0) {
            thumbnail = [[UIImage alloc] initWithData:data];
        }
        NSDate *end = [NSDate date];
        SHLogInfo(SHLogTagAPP, @"download thumbnail interval: %f", [end timeIntervalSinceDate:start]);
    }
#endif
    
    [[SHNetworkManager sharedNetworkManager] getImgCoverWithFullURL:camera_server.cover completion:^(BOOL isSuccess, id  _Nullable result) {
        if(isSuccess) {
            //NSString *urlStr = [NSString stringWithFormat:@"%@", err];
            //NSURL *url = [NSURL URLWithString:urlStr];
            
            NSData *imgData = [NSData dataWithContentsOfURL:result];
            if (imgData.length > 0) {
                thumbnail =  [UIImage imageWithData:imgData];
                SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:camera_server.uid devicePassword:camera_server.devicepassword id:camera_server.id thumbnail:thumbnail operable:permission];
                [[CoreDataHandler sharedCoreDataHander] addCamera:camera];
                NSError *err = nil;
                [[NSFileManager defaultManager] removeItemAtURL:result error:&err];
                if (err != nil) {
                    NSLog(@"delete file err:%@", err);
                }
            }
        }

    }];
    SHCameraHelper *camera = [SHCameraHelper cameraWithName:name cameraUid:camera_server.uid devicePassword:camera_server.devicepassword id:camera_server.id thumbnail:thumbnail operable:permission];
    SHLogInfo(SHLogTagAPP, @"===> camera: %@", camera);
    
    [[CoreDataHandler sharedCoreDataHander] addCamera:camera];
    
}

@end