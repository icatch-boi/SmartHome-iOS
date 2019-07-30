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
}

#pragma mark - Base Op
- (void)addFaceDataWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData {
    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:obj];
        [handle addFaceWithFaceID:faceID faceData:faceData];
    }];
}

- (void)deleteFacesWithFaceIDs:(NSArray<NSString *> *)facesIDs {
    [[[SHCameraManager sharedCameraManger] smarthomeCams] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHFaceDataHandler *handle = [[SHFaceDataHandler alloc] initWithCameraObject:obj];
        [handle deleteFacesWithFaceIDs:facesIDs];
    }];
}

- (void)loadFacesInfoWithCompletion:(FaceDataHandleCompletion _Nullable)completion {
    WEAK_SELF(self);
    [[SHNetworkManager sharedNetworkManager] getFacesInfoWithFinished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"getFacesInfo failed, error: %@", error.error_description);
            if (completion) {
                completion(NO);
            }
        } else {
            NSArray *faceInfoArray = (NSArray *)result;
            
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
    }];
}

- (void)saveFacesInfoToLocal:(NSArray *)faces {
    [[NSUserDefaults standardUserDefaults] setObject:faces forKey:kLocalFacesInfo];
}

@end
