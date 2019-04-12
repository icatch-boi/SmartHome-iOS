// SHLocalCamerasHelper.m

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
 
 // Created by zj on 2018/4/27 上午11:46.
    

#import "SHLocalCamerasHelper.h"
#import "SHShareCamera.h"

@interface SHLocalCamerasHelper ()

@property (nonatomic, strong) NSMutableArray *camerasArray;

@end

@implementation SHLocalCamerasHelper

- (void)prepareCamerasData {
    NSArray *cameras = [[CoreDataHandler sharedCoreDataHander] fetchedCamera];
    
    [self.camerasArray removeAllObjects];

    [self updateCacheCamerasWithLocalCameras:cameras];

    WEAK_SELF(self);
    [cameras enumerateObjectsUsingBlock:^(SHCamera *camera, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakself addShareCamera:camera];
        [weakself addCameraToCameraManager:camera];
    }];
    
    [self saveShareCameras];
}

- (void)addCameraToCameraManager:(SHCamera *)camera {
    NSArray<SHCameraObject *> *cacheCameras = [SHCameraManager sharedCameraManger].smarthomeCams;

    __block BOOL exist = NO;
    [cacheCameras enumerateObjectsUsingBlock:^(SHCameraObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([camera.cameraUid isEqualToString:obj.camera.cameraUid]) {
            obj.camera = camera;
            
            exist = YES;
            *stop = YES;
        }
    }];
    
    if (exist == NO) {
        [[SHCameraManager sharedCameraManger] addSHCameraObject:camera];
    }
}

- (void)addShareCamera:(SHCamera *)camera {
    SHShareCamera *shareCamera = [[SHShareCamera alloc] init];
    
    shareCamera.cameraUid = camera.cameraUid;
    shareCamera.cameraName = camera.cameraName;
    
    [self.camerasArray addObject:shareCamera];
}

- (void)saveShareCameras {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.camerasArray.copy];
    SHLogDebug(SHLogTagAPP, @"archive data: %@", data);
    [userDefault setObject:data forKey:kShareCameraInfoKey];
}

#pragma mark - init
- (NSMutableArray *)camerasArray {
    if (_camerasArray == nil) {
        _camerasArray = [NSMutableArray array];
    }
    
    return _camerasArray;
}

- (void)updateCacheCamerasWithLocalCameras:(NSArray *)localCameras {
    NSArray<SHCameraObject *> *cacheCameras = [SHCameraManager sharedCameraManger].smarthomeCams;
    SHLogInfo(SHLogTagAPP, @"Cache camera count: %ld", cacheCameras.count);
    
    WEAK_SELF(self);
    [cacheCameras enumerateObjectsUsingBlock:^(SHCameraObject * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakself checkLocalContainsCamera:obj localCameras:localCameras];
    }];
}

- (void)checkLocalContainsCamera:(SHCameraObject *)cacheCamera localCameras:(NSArray *)localCameras {
    __block BOOL exist = NO;
    
    [localCameras enumerateObjectsUsingBlock:^(SHCamera *localCam, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([localCam.cameraUid isEqualToString:cacheCamera.camera.cameraUid]) {
            exist = YES;
            *stop = YES;
        }
    }];
    
    if (!exist) {
        if (cacheCamera.startPV) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
            return;
        }
        [[SHCameraManager sharedCameraManger] removeSHCameraObject:cacheCamera];
    }
}

@end
