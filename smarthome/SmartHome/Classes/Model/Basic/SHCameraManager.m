//
//  SHCameraManager.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCameraManager.h"
@interface SHCameraManager ()
@property (nonatomic, readwrite) NSMutableArray *smarthomeCams;
@end

@implementation SHCameraManager

+ (instancetype)sharedCameraManger {
    static SHCameraManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.smarthomeCams = [[NSMutableArray alloc] init];
    });
    
    return instance;
}

- (void)addSHCameraObject:(SHCamera *)shCamera {
    if ([self containsObject:shCamera.cameraUid] == -1) {
        SHCameraObject *cameraObj = [SHCameraObject cameraObjectWithCamera:shCamera];
        [self.smarthomeCams addObject:cameraObj];
    }
}

- (void)removeSHCameraObject:(SHCameraObject *)shCameraobj {
    int index = [self containsObject:shCameraobj.camera.cameraUid];
    
    if (index != -1) {
        [self.smarthomeCams removeObjectAtIndex:index];
    } else {
        // when remove device from local db, uid will is nil.
        if (shCameraobj.camera.cameraUid == nil) {
            [self.smarthomeCams removeObject:shCameraobj];
        }
    }
}

- (int)containsObject:(NSString *)cameraUid {
    // -1:不包含 大于0:obj所在的下标
    __block int retVal = -1;
    
    [self.smarthomeCams enumerateObjectsUsingBlock:^(SHCameraObject *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cameraUid isEqualToString:obj.camera.cameraUid]) {
            *stop = YES;
            retVal = (int)idx;
        }
    }];
    
    return retVal;
}

- (SHCameraObject *)getSHCameraObjectWithCameraUid:(NSString *)uid {
    for (SHCameraObject *obj in self.smarthomeCams) {
        if ([obj.camera.cameraUid isEqualToString:uid]) {
            return obj;
        }
    }
    
    return nil;
}

- (void)removeAllCameraObjects {
    [self.smarthomeCams removeAllObjects];
}

- (void)unmappingAllCamera {
    if (self.smarthomeCams.count > 0) {
        for (SHCameraObject *obj in self.smarthomeCams) {
            [SHTutkHttp unregisterDevice:obj.camera.cameraUid];
        }
    } else {
        NSArray *cameras = [[CoreDataHandler sharedCoreDataHander] fetchedCamera];
        [cameras enumerateObjectsUsingBlock:^(SHCamera *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [SHTutkHttp unregisterDevice:obj.cameraUid];
        }];
    }
}

- (void)destroyAllDeviceResoure {
    [self.smarthomeCams enumerateObjectsUsingBlock:^(SHCameraObject * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isConnect) {
            [obj.sdk disableTutk];

            [obj disConnectWithSuccessBlock:nil failedBlock:nil];
        }
    }];
}

- (void)destroyAllDeviceResoureExcept:(NSString *)uid {
    [self.smarthomeCams enumerateObjectsUsingBlock:^(SHCameraObject * obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj.camera.cameraUid isEqualToString:uid] && obj.isConnect) {
            [obj.sdk disableTutk];
            
            [obj disConnectWithSuccessBlock:nil failedBlock:nil];
        }
    }];
}

@end
