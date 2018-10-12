// FileOperate.h

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
 
 // Created by sa on 2018/4/18 下午1:55.
    

#import <Foundation/Foundation.h>
#import "BasicStorageInfo.h"
#import "BasicFileInfo.h"
#import "BasicFileURLInfo.h"
#import "Token.h"
#import "Error.h"
@interface FileOperate : NSObject


- (void)getStorageInfoWithToken:(Token *)token
                   withDeviceID:(NSString *)deviceID
                  withStartDate:(NSString *)startDate
                    withEndDate:(NSString *)endDate
                        success:(void (^)(NSArray <BasicStorageInfo *> * _Nonnull))success
                        failure:(void (^)(Error * _Nonnull))failure;

- (void)getFileListWithToken:(Token *)token
                withDeviceID:(NSString *)deviceID
                    withDate:(NSString *)date
                     success:(nullable void (^)(NSArray <BasicFileInfo *> * _Nonnull basicFileInfo))success
                     failure:(nullable void (^)(Error* _Nonnull error))failure;

- (void)getThumbnailURLInfoWithToken:(Token *)token
                   withDeviceID:(NSString *)deviceID
                    withFileID:(NSString *)fileID
                     success:(nullable void (^)(BasicFileURLInfo * _Nonnull basicThumbnailURLInfo))success
                     failure:(nullable void (^)(Error* _Nonnull error))failure;

- (void)getFileURLInfoWithToken:(Token *)token
                        withDeviceID:(NSString *)deviceID
                       withFileID:(NSString *)fileID
                          success:(nullable void (^)(BasicFileURLInfo * _Nonnull basicThumbnailURLInfo))success
                          failure:(nullable void (^)(Error* _Nonnull error))failure;

- (void)deleteFileWithToken:(Token *)token
                  withDeviceID:(NSString *)deviceID
                 withFileID:(NSString *)fileID
                    success:(void (^)(void))success
                    failure:(nullable void (^)(Error* _Nonnull error))failure;

@end
