// SHENetworkManager.h

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
 
 // Created by zj on 2019/9/10 11:40 AM.
    

#import <Foundation/Foundation.h>
#import "SHIdentityInfo.h"
#import "SHS3DirectoryInfo.h"
#import <AWSS3/AWSS3.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SHERequestMethodGET,
    SHERequestMethodPOST,
    SHERequestMethodPUT,
    SHERequestMethodDELETE,
} SHERequestMethod;

typedef enum : NSUInteger {
    SHES3ProviderTypeUser,
    SHES3ProviderTypeDevice,
} SHES3ProviderType;

/**
 Request completion callback

 @param isSuccess Whether the request was successful
 @param result If request success return the requested data, Otherwise return error info.
 */
typedef void(^SHERequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
typedef void(^SHEDeleteFileCompletionBlock)(BOOL isSuccess);

typedef NS_ENUM(NSInteger, SHEError) {
    SHEErrorUnknown = -10000,
    SHEErrorInvalidParameters = -10001,
};
static NSString * const SHEErrorDomain = @"SHEErrorDomainUser"; //定义错误范围

@interface SHENetworkManager : NSObject

@property (nonatomic, strong) SHS3DirectoryInfo *userDirectoryInfo;
@property (nonatomic, copy, readonly) NSString *userIdentifier;
@property (nonatomic, strong) NSMutableDictionary<NSString *, SHS3DirectoryInfo *> *deviceDirectoryInfos;

+ (instancetype)sharedManager;

#pragma mark - Request method
- (void)tokenRequestWithMethod:(SHERequestMethod)method urlString:(NSString *)urlString parametes:(nullable id)parametes completion:(SHERequestCompletionBlock _Nullable)completion;
- (void)requestWithMethod:(SHERequestMethod)method urlString:(NSString *)urlString parametes:(nullable id)parametes completion:(SHERequestCompletionBlock _Nullable)completion;

#pragma mark - Common method
- (void)getObjectWithAWSS3Client:(AWSS3 *)s3client bucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion;
- (void)registerS3WithProviderType:(SHES3ProviderType)type identityPoolId:(NSString *)identityPoolId forKey:(NSString *)key;
- (void)listObjectsWithAWSS3Client:(AWSS3 *)s3client bucketName:(NSString *)bucketName prefix:(NSString *)prefix startKey:(NSString * _Nullable)startKey number:(NSInteger)number completion:(void (^)(AWSS3ListObjectsV2Output * _Nullable response, NSError * _Nullable error))completion;
- (void)deleteFileWithAWSS3Client:(AWSS3 *)s3client bucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHEDeleteFileCompletionBlock)completion;

- (NSError *)createInvalidParametersErrorWithDescription:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
