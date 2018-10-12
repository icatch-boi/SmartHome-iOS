// SHCameraListViewModel.m

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
 
 // Created by zj on 2018/3/21 下午3:08.
    

#import "SHCameraListViewModel.h"
#import "SHShareCamera.h"
#import "SHCameraViewModel.h"
#import "SHLocalCamerasHelper.h"

@interface SHCameraListViewModel () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSMutableArray *cameraList;
@property (nonatomic, strong) NSMutableArray *camerasArray;

@end

@implementation SHCameraListViewModel

- (void)loadCamerasWithCompletion:(void (^)())completion {
#if 0
    NSArray *cameras = [[CoreDataHandler sharedCoreDataHander] fetchedCamera];
    
    [self.camerasArray removeAllObjects];
    [[SHCameraManager sharedCameraManger] removeAllCameraObjects];
    [cameras enumerateObjectsUsingBlock:^(SHCamera *camera, NSUInteger idx, BOOL * _Nonnull stop) {
        [[SHCameraManager sharedCameraManger] addSHCameraObject:camera];
        [self addShareCamera:camera];
    }];
    
    [self saveShareCameras];
#endif
    [[[SHLocalCamerasHelper alloc] init] prepareCamerasData];
    [self addCameraToViewModel];
    
    if (completion) {
        completion();
    }
}

- (void)addCameraToViewModel {
    [self.cameraList removeAllObjects];

    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHCameraViewModel *cameraVM = [[SHCameraViewModel alloc] initWithCameraObject:obj];
        [self.cameraList addObject:cameraVM];
    }];
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
- (NSMutableArray *)cameraList {
    if (_cameraList == nil) {
        _cameraList = [NSMutableArray array];
    }
    
    return _cameraList;
}

- (NSMutableArray *)camerasArray {
    if (_camerasArray == nil) {
        _camerasArray = [NSMutableArray array];
    }
    
    return _camerasArray;
}

@end
