// SHENetworkManager+AWSS3.m

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
    

#import "SHENetworkManager+AWSS3.h"
#import "SHIdentityInfo.h"
#import <AWSS3/AWSS3.h>

@implementation SHENetworkManager (AWSS3)

#pragma mark - IdentityInfo
- (SHIdentityInfo *)getIdentityInfo {
    NSString *urlString = [kServerBaseURL stringByAppendingString:kAwsauth];

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block SHIdentityInfo *info = nil;
    [self tokenRequestWithMethod:SHERequestMethodGET urlString:urlString parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            info = [SHIdentityInfo identityInfoWithDict:result];
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return info;
}

- (void)getIdentityInfoWithCompletion:(SHERequestCompletionBlock)completion {
    NSString *urlString = [kServerBaseURL stringByAppendingString:kAwsauth];

    [self tokenRequestWithMethod:SHERequestMethodGET urlString:urlString parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess == YES && result != nil) {
            self.userIdentityInfo = [SHIdentityInfo identityInfoWithDict:result];
            
            if (completion) {
                completion(YES, result);
            }
        } else {
            if (completion) {
                completion(NO, result);
            }
        }
    }];
}

#pragma mark - Get Object
- (void)getObjectWithBucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion {
    if (self.userIdentityInfo == nil) {
        WEAK_SELF(self);
        [self getIdentityInfoWithCompletion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [weakself getObjectHandleWithBucketName:bucketName filePath:filePath completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [self getObjectHandleWithBucketName:bucketName filePath:filePath completion:completion];
    }
}

- (void)getObjectHandleWithBucketName:(NSString *)bucketName filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion {
    if (bucketName.length == 0 || filePath.length == 0) {
        if (completion) {
            completion(NO, @"Parameter is invalid");
        }
        
        return;
    }
    
    AWSS3GetObjectRequest *request = [[AWSS3GetObjectRequest alloc] init];
    request.bucket = bucketName;
    request.key = filePath;
    
    [[AWSS3 defaultS3] getObject:request completionHandler:^(AWSS3GetObjectOutput * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (completion) {
                completion(NO, error);
            }
        } else {
            if (completion) {
                completion(YES, response.body);
            }
        }
    }];
}

#pragma mark - Portrait
- (void)getUserPortrait:(SHERequestCompletionBlock)completion {
    [self getUserDataWithType:SHEUserDataTypePortrait parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
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

- (void)getFaceImageWithFaceid:(NSString *)faceid completion:(SHERequestCompletionBlock)completion {
    if (faceid.length == 0) {
        if (completion) {
            completion(NO, @"Paramete `faceid` can't be nil.");
        }
        
        return;
    }
    
    [self getUserDataWithType:SHEUserDataTypeFaceImage parametes:faceid completion:^(BOOL isSuccess, id  _Nullable result) {
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

- (void)getFaceSetDataWithFaceid:(NSString *)faceid completion:(SHERequestCompletionBlock)completion {
    if (faceid.length == 0) {
        if (completion) {
            completion(NO, @"Paramete `faceid` can't be nil.");
        }
        
        return;
    }
    
    [self getUserDataWithType:SHEUserDataTypeFaceSet parametes:faceid completion:completion];
}

#pragma mark - User Data
- (void)getUserDataWithType:(SHEUserDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    if (self.userDirectoryInfo == nil) {
        WEAK_SELF(self);
        [self getS3DirectoryInfoWithCompletion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [weakself getUserDataHandleWithType:type parametes:parametes completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }

        }];
    } else {
        [self getUserDataHandleWithType:type parametes:parametes completion:completion];
    }
}

- (void)getUserDataHandleWithType:(SHEUserDataType)type parametes:(nullable id)parametes completion:(SHERequestCompletionBlock)completion {
    NSString *bucketName = self.userDirectoryInfo.bucket;
    NSString *filePath = nil;
    
    switch (type) {
        case SHEUserDataTypePortrait:
            filePath = self.userDirectoryInfo.portrait;
            break;
            
        case SHEUserDataTypeFaceImage:
            filePath = self.userDirectoryInfo.faces;
            if (parametes != nil) {
                NSString *fileName = [NSString stringWithFormat:@"%@.jpg", parametes];
                filePath = [filePath stringByAppendingPathComponent:fileName];
            }
            
            break;
            
        case SHEUserDataTypeFaceSet:
            filePath = self.userDirectoryInfo.faces;
            if (parametes != nil) {
                filePath = [filePath stringByAppendingPathComponent:parametes];
            }
            
            break;
            
        default:
            break;
    }
    
    if (filePath != nil) {
        [self getObjectWithBucketName:bucketName filePath:filePath completion:completion];
    }
}

#pragma mark - S3DirectoryInfo
- (void)getS3DirectoryInfoWithCompletion:(SHERequestCompletionBlock)completion {
    NSString *urlString = [kServerBaseURL stringByAppendingString:kUserS3Path];
    
    [self tokenRequestWithMethod:SHERequestMethodGET urlString:urlString parametes:nil completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess == YES && result != nil) {
            self.userDirectoryInfo = [SHS3DirectoryInfo s3DirectoryInfoWithDict:result];
            SHLogInfo(SHLogTagAPP, @"User dir: %@", self.userDirectoryInfo);
            
            if (completion) {
                completion(YES, result);
            }
        } else {
            if (completion) {
                completion(NO, result);
            }
        }
    }];
}

@end
