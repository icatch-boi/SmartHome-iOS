// SHENetworkManager+DeviceAWSS3.m

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
    

#import "SHENetworkManager+DeviceAWSS3.h"

typedef enum : NSUInteger {
    SHEDeviceDataTypeCover,
    SHEDeviceDataTypeStranger,
    SHEDeviceDataTypeMessages,
    SHEDeviceDataTypeFiles,
} SHEDeviceDataType;

@implementation SHENetworkManager (DeviceAWSS3)

#pragma mark - Device Resouce
- (void)getDeviceCoverWithDeviceID:(NSString *)deviceID completion:(SHERequestCompletionBlock)completion {
    [self getDeviceDataWithDeviceID:deviceID dataType:SHEDeviceDataTypeCover parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
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

- (void)getStrangerFaceImageWithDeviceID:(NSString *)deviceID completion:(SHERequestCompletionBlock)completion {
    [self getDeviceDataWithDeviceID:deviceID dataType:SHEDeviceDataTypeStranger parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
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

- (void)getDeviceMessageFileWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(SHERequestCompletionBlock)completion {
    if (fileName.length == 0) {
        if (completion) {
            completion(NO, @"Paramete `fileName` can't be nil.");
        }
        
        return;
    }
    
    [self getDeviceDataWithDeviceID:deviceID dataType:SHEDeviceDataTypeMessages parametes:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
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
- (void)getDeviceDataWithDeviceID:(NSString *)deviceID dataType:(SHEDeviceDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    if (self.deviceDirectoryInfos[deviceID] == nil) {
        WEAK_SELF(self);
        [self getDeviceS3DirectoryInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                weakself.deviceDirectoryInfos[deviceID] = result;
                
                [weakself getDeviceDataHandleWithDeviceID:deviceID dataType:type parametes:parametes completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [self getDeviceDataHandleWithDeviceID:deviceID dataType:type parametes:parametes completion:completion];
    }
}

- (void)getDeviceDataHandleWithDeviceID:(NSString *)deviceID dataType:(SHEDeviceDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    SHS3DirectoryInfo *deviceDirectoryInfo = self.deviceDirectoryInfos[deviceID];
    if (deviceDirectoryInfo == nil) {
        if (completion) {
            completion(NO, @"Parameter `deviceDirectoryInfo` can't be nil");
        }
        return;
    }
    
    NSString *bucketName = deviceDirectoryInfo.bucket;
    NSString *filePath = nil;
    
    switch (type) {
        case SHEDeviceDataTypeCover:
            filePath = deviceDirectoryInfo.cover;
            break;
            
        case SHEDeviceDataTypeStranger:
            filePath = deviceDirectoryInfo.faces;
            break;
            
        case SHEDeviceDataTypeMessages:
            filePath = deviceDirectoryInfo.messages;
            if (parametes != nil) {
                filePath = [filePath stringByAppendingPathComponent:parametes];
            }
            
            break;
            
        case SHEDeviceDataTypeFiles:
            filePath = deviceDirectoryInfo.files;
            break;
            
        default:
            break;
    }
    
    if (filePath != nil) {
        [self getDeviceObjectWithDeviceID:deviceID bucketName:bucketName filePath:filePath completion:completion];
    }
}

#pragma mark - Get Object
- (void)getDeviceObjectWithDeviceID:(NSString *)deviceID bucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion {

    NSString *key = deviceID;
    AWSS3 *s3 = [AWSS3 S3ForKey:key];
    if (s3 == nil) {
        WEAK_SELF(self);
        [self getDeviceIdentityInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                SHIdentityInfo *info = result;
                
                [weakself registerS3WithProviderType:SHES3ProviderTypeDevice identityPoolId:info.IdentityPoolId forKey:key];
                
                [weakself getDeviceObjectWithDeviceID:deviceID bucketName:bucketName filePath:filePath completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [self getObjectWithAWSS3Client:s3 bucketName:bucketName filePath:filePath completion:completion];
    }
}

#pragma mark - Device IdentityInfo
- (SHIdentityInfo *)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block SHIdentityInfo *info = nil;
    [self getDeviceIdentityInfoWithDeviceid:deviceid completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            info = result;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return info;
}

- (void)getDeviceIdentityInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion {
    if (deviceid.length == 0) {
        SHLogError(SHLogTagAPP, @"Parameter `deviceid` can't be nil.");
        if (completion) {
            completion(NO, @"Parameter `deviceid` can't be nil.");
        }
        
        return;
    }
    
    NSDictionary *parametes = @{
                                @"id": deviceid
                                };
    
    NSString *urlString = [kServerBaseURL stringByAppendingString:kDeviceAWSAuth];
    
    [self tokenRequestWithMethod:SHERequestMethodGET urlString:urlString parametes:parametes completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess == YES && result != nil) {
            if (completion) {
                completion(YES, [SHIdentityInfo identityInfoWithDict:result]);
            }
        } else {
            if (completion) {
                completion(NO, result);
            }
        }
    }];
}

#pragma mark - Device S3DirectoryInfo
- (void)getDeviceS3DirectoryInfoWithDeviceid:(NSString *)deviceid completion:(SHERequestCompletionBlock)completion {
    if (deviceid.length == 0) {
        SHLogError(SHLogTagAPP, @"Parameter `deviceid` can't be nil.");
        if (completion) {
            completion(NO, @"Parameter `deviceid` can't be nil.");
        }
        
        return;
    }
    
    NSDictionary *parametes = @{
                                @"id": deviceid
                                };
    
    NSString *urlString = [kServerBaseURL stringByAppendingString:kDeviceS3Path];
    
    [self tokenRequestWithMethod:SHERequestMethodGET urlString:urlString parametes:parametes completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess == YES && result != nil) {
            SHLogInfo(SHLogTagAPP, @"Device dir: %@", result);
            
            if (completion) {
                completion(YES, [SHS3DirectoryInfo s3DirectoryInfoWithDict:result]);
            }
        } else {
            if (completion) {
                completion(NO, result);
            }
        }
    }];
}

@end
