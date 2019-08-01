// SHFaceDataManager.h

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
    

#import <Foundation/Foundation.h>
#import "FRDFaceInfo.h"
#import "SHFaceDataCommon.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^FaceDataLoadCompletion)(BOOL isSuccess);
typedef void(^FaceDataAddCompletion)(BOOL isSuccess);

@interface SHFaceDataManager : NSObject

@property (nonatomic, strong, readonly) NSMutableArray<FRDFaceInfo *> *facesInfoArray;

+ (instancetype)sharedFaceDataManager;

- (void)loadFacesInfoWithCompletion:(FaceDataLoadCompletion _Nullable)completion;

- (void)addFaceDataWithFaceID:(NSString *)faceID faceData:(NSArray<NSData *> *)faceData completion:(FaceDataAddCompletion _Nullable)completion;
- (void)deleteFacesWithFaceIDs:(NSArray<NSString *> *)facesIDs;

- (BOOL)needsSyncFaceDataWithCameraObject:(SHCameraObject *)shCamObj;
- (void)syncFaceDataWithCameraObject:(SHCameraObject *)shCamObj completion:(FaceDataHandleCompletion _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
