// SHFaceDataHandler.h

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
    

#import <Foundation/Foundation.h>
#import "SHFaceDataCommon.h"

NS_ASSUME_NONNULL_BEGIN

@class FRDFaceInfo;
@interface SHFaceDataHandler : NSObject

- (instancetype)init __attribute__((unavailable("Disabled. Please use the 'initWithCameraObject' methods instead.")));
- (instancetype)initWithCameraObject:(SHCameraObject *)camObj;

- (void)addFaceWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData completion:(FaceDataHandleCompletion _Nullable)completion;
- (void)deleteFacesWithFaceIDs:(NSArray<NSString *> *)facesIDs;

- (BOOL)checkNeedSyncFaceDataWithRemoteFaceInfo:(NSArray<FRDFaceInfo *> *)facesInfoArray;
- (void)syncFaceDataWithRemoteFaceInfo:(NSArray<FRDFaceInfo *> *)facesInfoArray completion:(FaceDataHandleCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
