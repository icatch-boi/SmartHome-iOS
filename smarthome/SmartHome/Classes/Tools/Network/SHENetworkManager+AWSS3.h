// SHENetworkManager+AWSS3.h

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
 
 // Created by zj on 2019/9/10 2:51 PM.
    

#import "SHENetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kUserAWSAuth = @"v1/users/awsauth";
static NSString * const kUserS3Path = @"v1/users/s3path";
static NSString * const kDeviceAWSAuth = @"v1/devices/awsauth";
static NSString * const kDeviceS3Path = @"v1/devices/s3path";

typedef enum : NSUInteger {
    SHEUserDataTypePortrait,
    SHEUserDataTypeFaceImage,
    SHEUserDataTypeFaceSet,
} SHEUserDataType;

@class SHIdentityInfo;
@interface SHENetworkManager (AWSS3)

#pragma mark - User Resoure
- (SHIdentityInfo *)getUserIdentityInfo;

/**
 Get user portrait data

 @param completion Request completion result, If success return `portrait' image,
 Otherwise return error info.
 */
- (void)getUserPortrait:(SHERequestCompletionBlock)completion;

- (void)getFaceImageWithFaceid:(NSString *)faceid completion:(SHERequestCompletionBlock)completion;
- (void)getFaceSetDataWithFaceid:(NSString *)faceid completion:(SHERequestCompletionBlock)completion;

#pragma mark - Device Resoure
- (SHIdentityInfo *)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid;
- (void)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion;
- (void)getDeviceS3DirectoryInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion;

#pragma mark - Get Obj
- (void)getObjectHandleWithBucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
