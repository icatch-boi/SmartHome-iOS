// SHENetworkManager+DeviceAWSS3.h

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
 
 // Created by zj on 2019/9/24 7:26 PM.
    

#import "SHENetworkManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kDeviceAWSAuth = @"v1/devices/awsauth";
static NSString * const kDeviceS3Path = @"v1/devices/s3path";

@interface SHENetworkManager (DeviceAWSS3)

#pragma mark - Device IdentityInfo
- (SHIdentityInfo *)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid;
- (void)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion;

#pragma mark - Device S3DirectoryInfo
- (void)getDeviceS3DirectoryInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion;

#pragma mark - Device Resoure
- (void)getDeviceCoverWithDeviceID:(NSString *)deviceID completion:(SHERequestCompletionBlock)completion;
- (void)getStrangerFaceImageWithDeviceID:(NSString *)deviceID completion:(SHERequestCompletionBlock)completion;
- (void)getDeviceMessageFileWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(SHERequestCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
