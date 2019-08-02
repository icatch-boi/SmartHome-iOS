// SHFaceDataManager.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
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
 
 // Created by zj on 2019/7/30 4:21 PM.
    

#import "SHFaceDataManager.h"
#import "SHFaceDataHandler.h"
#import "SHNetworkManager+SHFaceHandle.h"
#import "FRDCommonHeader.h"

@interface SHFaceDataManager ()

@property (nonatomic, strong) NSMutableArray<FRDFaceInfo *> *facesInfoArray;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@property (nonatomic, strong) dispatch_group_t faceHandleGroup;
@property (nonatomic, strong) dispatch_queue_t faceHandleQueue;
@property (nonatomic, assign) BOOL alreadyLoad;

@end

@implementation SHFaceDataManager

#pragma mark - Init
+ (instancetype)sharedFaceDataManager {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nullptr] init];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedFaceDataManager];
}

- (instancetype)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __block id self = [super init];
        if (self) {
            [self singletonInit];
        }
    });
    
    return self;
}

- (void)singletonInit {
    self.facesInfoArray = [[NSMutableArray alloc] init];
    self.semaphore = dispatch_semaphore_create(1);
    self.faceHandleGroup = dispatch_group_create();
    self.faceHandleQueue = dispatch_queue_create("com.icatchtek.FaceHandle", DISPATCH_QUEUE_CONCURRENT);
    self.alreadyLoad = NO;
}

#pragma mark - Base Op
- (void)addFaceDataWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData completion:(FaceDataAddCompletion _Nullable)completion {
#if 0
    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:obj];
        [handle addFaceWithFaceID:faceID faceData:faceData completion:nil];
    }];
#else
    __block BOOL isSuccess = NO;
    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        dispatch_group_enter(self.faceHandleGroup);
        dispatch_async(self.faceHandleQueue, ^{
            SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:obj];
            [handle addFaceWithFaceID:faceID faceData:faceData completion:^(NSDictionary<NSString *,NSNumber *> * _Nullable result) {
                if (result != nil) {
                    NSString *key = result.keyEnumerator.nextObject;
                    NSNumber *value = result[key];
                    if (value.intValue == 0) {
                        isSuccess = YES;
                    }
                }
                
                dispatch_group_leave(self.faceHandleGroup);
            }];
        });
    }];
    
    dispatch_group_notify(self.faceHandleGroup, dispatch_get_main_queue(), ^{
        if (completion) {
            completion(isSuccess);
        }
    });
#endif
}

- (void)deleteFacesWithFaceIDs:(NSArray<NSString *> *)facesIDs {
    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:obj];
        [handle deleteFacesWithFaceIDs:facesIDs];
    }];
}

- (void)loadFacesInfoWithCompletion:(FaceDataLoadCompletion _Nullable)completion {
    WEAK_SELF(self);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kWaitTimeout);
    if (dispatch_semaphore_wait(self.semaphore, time) != 0) {
        SHLogWarn(SHLogTagAPP, @"Wait time out.");
    }
    [[SHNetworkManager sharedNetworkManager] getFacesInfoWithFinished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"getFacesInfo failed, error: %@", error.error_description);
            if (completion) {
                completion(NO);
            }
        } else {
            NSArray *faceInfoArray = (NSArray *)result;
            SHLogInfo(SHLogTagAPP, @"Get face info: %@", result);
            
            NSMutableArray *faceInfoModelMArray = [NSMutableArray arrayWithCapacity:faceInfoArray.count];
            [faceInfoArray enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                FRDFaceInfo *faceInfo = [FRDFaceInfo faceInfoWithDict:obj];
                [faceInfoModelMArray addObject:faceInfo];
            }];
            
            [weakself.facesInfoArray removeAllObjects];
            [weakself.facesInfoArray addObjectsFromArray:faceInfoModelMArray.copy];
            
            [weakself saveFacesInfoToLocal:result];
            
            if (completion) {
                completion(YES);
            }
        }
        
        dispatch_semaphore_signal(self.semaphore);
    }];
    
    self.alreadyLoad = YES;
}

- (void)saveFacesInfoToLocal:(NSArray *)faces {
    [[NSUserDefaults standardUserDefaults] setObject:faces forKey:kLocalFacesInfo];
}

- (BOOL)needsSyncFaceDataWithCameraObject:(SHCameraObject *)shCamObj {
    self.alreadyLoad ? void() : [self loadFacesInfoWithCompletion:nil];
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kWaitTimeout);
    if (dispatch_semaphore_wait(self.semaphore, time) != 0) {
        SHLogWarn(SHLogTagAPP, @"Wait time out");
    }
    
    SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:shCamObj];
    BOOL need = [handle checkNeedSyncFaceDataWithRemoteFaceInfo:self.facesInfoArray];
    
    dispatch_semaphore_signal(self.semaphore);
    
    return need;
}

- (void)syncFaceDataWithCameraObject:(SHCameraObject *)shCamObj completion:(FaceDataHandleCompletion _Nullable)completion {
    self.alreadyLoad ? void() : [self loadFacesInfoWithCompletion:nil];
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, kWaitTimeout);
    if (dispatch_semaphore_wait(self.semaphore, time) != 0) {
        SHLogWarn(SHLogTagAPP, @"Wait time out");
    }
    
    SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:shCamObj];
    [handle syncFaceDataWithRemoteFaceInfo:self.facesInfoArray completion:^(NSDictionary<NSString *,NSNumber *> * _Nullable result) {
        dispatch_semaphore_signal(self.semaphore);

        if (completion) {
            completion(result);
        }
    }];
}

@end
