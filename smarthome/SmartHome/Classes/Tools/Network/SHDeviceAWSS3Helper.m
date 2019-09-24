// SHDeviceAWSS3Helper.m

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
 
 // Created by zj on 2019/9/23 5:07 PM.
    

#import "SHDeviceAWSS3Helper.h"
#import "SHDeviceAuthenticatedIdentityProvider.h"

typedef enum : NSUInteger {
    SHEDeviceDataTypeCover,
    SHEDeviceDataTypeStranger,
    SHEDeviceDataTypeMessages,
    SHEDeviceDataTypeFiles,
} SHEDeviceDataType;

@interface SHDeviceAWSS3Helper ()

@property (nonatomic, copy) NSString *deviceID;
@property (nonatomic, strong) SHIdentityInfo *deviceIdentityInfo;
@property (nonatomic, strong) SHS3DirectoryInfo *deviceDirectoryInfo;

@end

@implementation SHDeviceAWSS3Helper

#pragma mark - Init
- (instancetype)initWithDeviceid:(NSString *)deviceid
{
    self = [super init];
    if (self) {
        self.deviceID = deviceid;
        
        [self configAWSService];
    }
    return self;
}

+ (instancetype)deviceAWSS3HelperWithDeviceid:(NSString *)deviceid {
    return [[self alloc] initWithDeviceid:deviceid];
}

- (void)configAWSService {
    if (self.deviceIdentityInfo != nil) {
        SHDeviceAuthenticatedIdentityProvider *devAuth = [[SHDeviceAuthenticatedIdentityProvider alloc] initWithRegionType:AWSRegionCNNorth1 identityPoolId:self.deviceIdentityInfo.IdentityPoolId useEnhancedFlow:YES identityProviderManager:nil deviceID:self.deviceID];
        AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc]
                                                              initWithRegionType:AWSRegionCNNorth1
                                                              identityProvider:devAuth];
        
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionCNNorthWest1 credentialsProvider:credentialsProvider];
        
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    }
}

- (void)setDeviceIdentityInfo:(SHIdentityInfo *)deviceIdentityInfo {
    _deviceIdentityInfo = deviceIdentityInfo;
    
    if (deviceIdentityInfo != nil) {
        [self configAWSService];
    }
}

#pragma mark - Resouce
- (void)getDeviceCoverWithCompletion:(SHERequestCompletionBlock)completion {
    [self getDeviceDataWithDataType:SHEDeviceDataTypeCover parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            UIImage *image = [[UIImage alloc] initWithData:result];
            if (completion) {
                completion(isSuccess, image);
            }
        } else {
            if (completion) {
                completion(isSuccess, result);
            }
        }
    }];
}

- (void)getStrangerFaceImageWithCompletion:(SHERequestCompletionBlock)completion {
    [self getDeviceDataWithDataType:SHEDeviceDataTypeStranger parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            UIImage *image = [[UIImage alloc] initWithData:result];
            if (completion) {
                completion(isSuccess, image);
            }
        } else {
            if (completion) {
                completion(isSuccess, result);
            }
        }
    }];
}

- (void)getDeviceMessageFileWithFileName:(NSString *)fileName completion:(SHERequestCompletionBlock)completion {
    if (fileName.length == 0) {
        if (completion) {
            completion(NO, @"Paramete `fileName` can't be nil.");
        }
        
        return;
    }
    
    [self getDeviceDataWithDataType:SHEDeviceDataTypeMessages parametes:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            UIImage *image = [[UIImage alloc] initWithData:result];
            if (completion) {
                completion(isSuccess, image);
            }
        } else {
            if (completion) {
                completion(isSuccess, result);
            }
        }
    }];
}

#pragma mark - Device Data
- (void)getDeviceDataWithDataType:(SHEDeviceDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    if (self.deviceDirectoryInfo == nil) {
        WEAK_SELF(self);
        [[SHENetworkManager sharedManager] getDeviceS3DirectoryInfoWithDeviceid:self.deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                weakself.deviceDirectoryInfo = result;
                
                [weakself getDeviceDataHandleWithDataType:type parametes:parametes completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [self getDeviceDataHandleWithDataType:type parametes:parametes completion:completion];
    }
}

- (void)getDeviceDataHandleWithDataType:(SHEDeviceDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    NSString *bucketName = self.deviceDirectoryInfo.bucket;
    NSString *filePath = nil;
    
    switch (type) {
        case SHEDeviceDataTypeCover:
            filePath = self.deviceDirectoryInfo.cover;
            break;
            
        case SHEDeviceDataTypeStranger:
            filePath = self.deviceDirectoryInfo.faces;
            break;
            
        case SHEDeviceDataTypeMessages:
            filePath = self.deviceDirectoryInfo.messages;
            if (parametes != nil) {
                filePath = [filePath stringByAppendingPathComponent:parametes];
            }
            
            break;
            
        case SHEDeviceDataTypeFiles:
            filePath = self.deviceDirectoryInfo.files;
            break;
            
        default:
            break;
    }
    
    if (filePath != nil) {
        [self getDeviceObjectWithBucketName:bucketName filePath:filePath completion:completion];
    }
}

#pragma mark - Get Object
- (void)getDeviceObjectWithBucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion {
    if (self.deviceIdentityInfo == nil) {
        WEAK_SELF(self);
        [[SHENetworkManager sharedManager] getDeviceIdentityInfoWithDeviceid:self.deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                weakself.deviceIdentityInfo = result;
                
                [[SHENetworkManager sharedManager] getObjectHandleWithBucketName:bucketName filePath:filePath completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [[SHENetworkManager sharedManager] getObjectHandleWithBucketName:bucketName filePath:filePath completion:completion];
    }
}

@end
