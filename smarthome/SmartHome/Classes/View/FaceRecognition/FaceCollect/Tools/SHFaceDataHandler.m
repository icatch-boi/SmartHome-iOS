// SHFaceDataHandler.m

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
 
 // Created by zj on 2019/7/29 8:04 PM.
    

#import "SHFaceDataHandler.h"
#import "SHSDKEventListener.hpp"
#import "FRDFaceInfo.h"
#import "SHNetworkManager+SHFaceHandle.h"

@interface SHFaceDataHandler ()

@property (nonatomic, strong) SHObserver *addFaceDataObserver;
@property (nonatomic, weak) SHCameraObject *shCamObj;
@property (nonatomic, strong) NSArray<FRDFaceInfo *> *facesInfoArray;
@property (nonatomic, strong) NSMutableArray<FRDFaceInfo *> *faceidToAdd;
@property (nonatomic, assign, getter=isSyncFaceData) BOOL syncFaceData;
@property (nonatomic, copy) FaceDataHandleCompletion completion;

@end

@implementation SHFaceDataHandler

- (instancetype)initWithCameraObject:(SHCameraObject *)camObj {
    self = [super init];
    if (self) {
        self.shCamObj = camObj;
    }
    return self;
}

- (void)addFaceWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return;
    }
    
    int totalSize = 0;
    std::vector<ICatchFrameBuffer *> faceDataSets;
    for (NSData *data in faceData) {
        ICatchFrameBuffer *buffer = new ICatchFrameBuffer((unsigned char *)data.bytes, data.length + 1);
        buffer->setFrameSize(data.length);
        faceDataSets.push_back(buffer);
        totalSize += data.length;
    }
    
    int ret = [self.shCamObj.sdk initializeSHSDK:self.shCamObj.camera.cameraUid devicePassword:self.shCamObj.camera.devicePassword];
    if (ret == ICH_SUCCEED) {
        [self addSetupFaceDataObserver];
        ret = self.shCamObj.sdk.control->addFace(faceID.intValue, totalSize, faceDataSets, true);
        if (ret != ICH_SUCCEED) {
            SHLogError(SHLogTagAPP, @"addFace failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
        }
    } else {
        SHLogError(SHLogTagAPP, @"connect device failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
    }
}

- (void)addSetupFaceDataObserver {
    SHSDKEventListener *startDownloadlListener = new SHSDKEventListener(self, @selector(addFaceResultHandle:));
    self.addFaceDataObserver = [SHObserver cameraObserverWithListener:startDownloadlListener eventType:ICATCH_EVENT_ADD_FACE_RESULT isCustomized:NO isGlobal:NO];
    
    [self.shCamObj.sdk addObserver:self.addFaceDataObserver];
}

- (void)removeSetupFaceDataObserver {
    if (self.addFaceDataObserver != nil) {
        [self.shCamObj.sdk removeObserver:self.addFaceDataObserver];
        
        if (self.addFaceDataObserver.listener) {
            delete self.addFaceDataObserver.listener;
            self.addFaceDataObserver.listener = NULL;
        }
        
        self.addFaceDataObserver = nil;
    }
}

- (void)addFaceResultHandle:(SHICatchEvent *)event {
    int faceid = event.intValue1;
    int ret = event.intValue2;
    
    if (ret == 0) {
        SHLogInfo(SHLogTagAPP, @"add face success, face id: %d", faceid);
    } else {
        SHLogError(SHLogTagAPP, @"add face failed, face id: %d", faceid);
    }
    
    if (self.syncFaceData == NO) {
        [self removeSetupFaceDataObserver];
        [self.shCamObj.sdk destroySHSDK];
    } else {
        __block NSUInteger index;
        [self.faceidToAdd enumerateObjectsUsingBlock:^(FRDFaceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (faceid == obj.faceid.intValue) {
                index = idx;
                *stop = YES;
            }
        }];
        
        [self.faceidToAdd removeObjectAtIndex:index];
        if (self.faceidToAdd.count == 0) {
            self.syncFaceData = NO;
            [self removeSetupFaceDataObserver];
            if (self.completion) {
                self.completion();
            }
        }
    }
}

- (void)deleteFacesWithFaceIDs:(NSArray<NSString *> *)facesIDs {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return;
    }
    
    if (facesIDs.count <= 0) {
        SHLogWarn(SHLogTagAPP, @"Face id is empty.");
        return;
    }
    
    std::vector<int> faceIdList;
    for (NSString *faceid in facesIDs) {
        faceIdList.push_back(faceid.intValue);
    }
    
    int ret = [self.shCamObj.sdk initializeSHSDK:self.shCamObj.camera.cameraUid devicePassword:self.shCamObj.camera.devicePassword];
    if (ret == ICH_SUCCEED) {
        ret = self.shCamObj.sdk.control->deleteFaces(faceIdList);
        if (ret != ICH_SUCCEED) {
            SHLogError(SHLogTagAPP, @"delete face failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
        }
        
        [self.shCamObj.sdk destroySHSDK];
    } else {
        SHLogError(SHLogTagAPP, @"connect device failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
    }
}

- (BOOL)checkNeedSyncFaceDataWithRemoteFaceInfo:(NSArray<FRDFaceInfo *> *)facesInfoArray {
    BOOL need = NO;
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return need;
    }
    
    std::vector<int> faceIdList;
    for (FRDFaceInfo *info in facesInfoArray) {
        faceIdList.push_back(info.faceid.intValue);
    }
    
    need = self.shCamObj.sdk.control->isNeedSyncFaceData(faceIdList);
    
    return need;
}

- (void)syncFaceDataWithRemoteFaceInfo:(NSArray<FRDFaceInfo *> *)facesInfoArray completion:(FaceDataHandleCompletion)completion {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        if (completion) {
            completion();
        }
        return;
    }
    
    NSArray<NSString *> *localFaceID = [self getFacesID];
    if (localFaceID == nil) {
        SHLogError(SHLogTagAPP, @"Get face id failed.");
        if (completion) {
            completion();
        }
        return;
    }
    
    if (facesInfoArray.count == 0) {
        SHLogWarn(SHLogTagAPP, @"Remote face info is empty.");
        [self deleteFacesHandleWithFacesID:localFaceID];
        
        if (completion) {
            completion();
        }
        return;
    }
    
    self.facesInfoArray = facesInfoArray;
    self.completion = completion;
    self.syncFaceData = YES;
    
    if (localFaceID.count == 0) {
        [self addFacesToFWWithFacesInfo:facesInfoArray];
    } else {
        NSMutableArray<FRDFaceInfo *> *faceidToAdd = [[NSMutableArray alloc] init];
        [facesInfoArray enumerateObjectsUsingBlock:^(FRDFaceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![localFaceID containsObject:obj.faceid]) {
                [faceidToAdd addObject:obj];
            }
        }];
        
        NSMutableArray<NSString *> *faceidToDelete = [[NSMutableArray alloc] init];
        [localFaceID enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (![self remoteContainsFaceID:obj]) {
                [faceidToDelete addObject:obj];
            }
        }];
        
        // 1. delete
        [self deleteFacesHandleWithFacesID:faceidToDelete.copy];
        // 2. add
        [self addFacesToFWWithFacesInfo:faceidToAdd.copy];
    }
}

- (void)addFacesToFWWithFacesInfo:(NSArray<FRDFaceInfo *> *)faceInfoArray {
    [self.faceidToAdd removeAllObjects];
    [self.faceidToAdd addObjectsFromArray:faceInfoArray];
    [self addSetupFaceDataObserver];
    
    [faceInfoArray enumerateObjectsUsingBlock:^(FRDFaceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addFaceDataToFWWithFaceInfo:obj];
    }];
}

- (void)addFaceDataToFWWithFaceInfo:(FRDFaceInfo *)faceinfo {
    WEAK_SELF(self);
    [self getFaceDataSetWithFaceInfo:faceinfo completion:^(NSDictionary *result) {
        STRONG_SELF(self);
        
        if (result != nil) {
            NSMutableArray *temp = [NSMutableArray arrayWithCapacity:result.count];
            
            for (NSString *key in result.keyEnumerator) {
                NSData *data = [[NSData alloc] initWithBase64EncodedString:result[key] options:NSDataBase64DecodingIgnoreUnknownCharacters];
                
                if (data != nil) {
                    [temp addObject:data];
                }
            }
            
            if (temp.count > 0) {
                [self addFaceHandleWithFaceID:faceinfo.faceid faceData:temp.copy];
            }
        }
    }];
}

- (void)getFaceDataSetWithFaceInfo:(FRDFaceInfo *)info completion:(void (^)(NSDictionary *result))completion {
    if (info.faceDataSet != nil) {
        if (completion) {
            completion(info.faceDataSet);
        }
        
        return;
    }
    
    [[SHNetworkManager sharedNetworkManager] getFaceDataSetWithFaceid:info.faceid finished:^(id  _Nullable result, ZJRequestError * _Nullable error) {
        if (error != nil) {
            SHLogError(SHLogTagAPP, @"getFacesInfo failed, error: %@", error.error_description);
            if (completion) {
                completion(nil);
            }
        } else {
            id obj = [NSJSONSerialization JSONObjectWithData:result options:0 error:NULL];
//            SHLogInfo(SHLogTagAPP, @"result: %@", obj);
            info.faceDataSet = obj;
            
            if (completion) {
                completion(obj);
            }
        }
    }];
}

- (BOOL)remoteContainsFaceID:(NSString *)faceid {
    __block BOOL contains = NO;
    
    [self.facesInfoArray enumerateObjectsUsingBlock:^(FRDFaceInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.faceid isEqualToString:faceid]) {
            contains = YES;
            *stop = YES;
        }
    }];
    
    return contains;
}

- (NSArray<NSString *> *)getFacesID {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return nil;
    }
    
    std::vector<int> faceIdList;
    
    int ret = self.shCamObj.sdk.control->getFaceList(faceIdList);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagAPP, @"Get face list failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
        return nil;
    }
    
    NSMutableArray<NSString *> *temp = [[NSMutableArray alloc] init];
    for (int faceid: faceIdList) {
        [temp addObject:@(faceid).stringValue];;
    }
    
    return temp.copy;
}

- (void)addFaceHandleWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return;
    }
    
    int totalSize = 0;
    std::vector<ICatchFrameBuffer *> faceDataSets;
    for (NSData *data in faceData) {
        ICatchFrameBuffer *buffer = new ICatchFrameBuffer((unsigned char *)data.bytes, data.length + 1);
        buffer->setFrameSize(data.length);
        faceDataSets.push_back(buffer);
        totalSize += data.length;
    }
    
    int ret = self.shCamObj.sdk.control->addFace(faceID.intValue, totalSize, faceDataSets, true);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagAPP, @"addFace failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
    }
}

- (void)deleteFacesHandleWithFacesID:(NSArray<NSString *> *)facesIDs {
    if (self.shCamObj.camera.operable != 1) {
        SHLogWarn(SHLogTagAPP, @"You do not have permission to operate this device, device name: %@", self.shCamObj.camera.cameraName);
        return;
    }
    
    if (facesIDs.count == 0) {
        SHLogWarn(SHLogTagAPP, @"Face id is empty.");
        return;
    }
    
    std::vector<int> faceIdList;
    for (NSString *faceid in facesIDs) {
        faceIdList.push_back(faceid.intValue);
    }
    
    int ret = self.shCamObj.sdk.control->deleteFaces(faceIdList);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagAPP, @"delete face failed, ret: %d, device name: %@", ret, self.shCamObj.camera.cameraName);
    }
}

#pragma mark - Lazy load
- (NSMutableArray<FRDFaceInfo *> *)faceidToAdd {
    if (_faceidToAdd == nil) {
        _faceidToAdd = [[NSMutableArray alloc] init];
    }
    
    return _faceidToAdd;
}

@end
