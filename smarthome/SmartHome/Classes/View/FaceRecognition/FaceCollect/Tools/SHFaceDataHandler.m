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

@interface SHFaceDataHandler ()

@property (nonatomic, strong) SHObserver *addFaceDataObserver;
@property (nonatomic, weak) SHCameraObject *shCamObj;

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
    
    [self removeSetupFaceDataObserver];
    [self.shCamObj.sdk destroySHSDK];
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

@end
