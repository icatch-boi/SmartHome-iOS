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
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil.");

        if (completion) {
            completion(NO, @"Paramete `deviceID` can't be nil.");
        }
        
        return;
    }
    
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
        SHLogError(SHLogTagAPP, @"Paramete `deviceDirectoryInfo` can't be nil.");

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
            
        case SHEDeviceDataTypeStranger: {
            filePath = deviceDirectoryInfo.faces;
            NSString *fileName = @"face.jpg";
            filePath = [filePath stringByAppendingPathComponent:fileName];
        }
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
        [self getObjectWithAWSS3Client:s3 bucketName:bucketName filePath:filePath completion:^(BOOL isSuccess, id  _Nullable result) {
            if (completion) {
                isSuccess ? completion(isSuccess, ((AWSS3GetObjectOutput *)result).body) : completion(isSuccess, result);
            }
        }];
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
            SHLogInfo(SHLogTagAPP, @"Device identity info: %@", result);

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

#pragma mark - List Files
- (void)listFilesWithDeviceID:(NSString *)deviceID oneday:(NSDate * _Nullable)oneday completion:(SHEListFilesCompletionBlock)completion {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil.");

        if (completion) {
            completion(nil, [self createInvalidParametersErrorWithDescription:@"Parameter `deviceID` can't be nil."]);
        }
        
        return;
    }
    
    if (oneday == nil) {
        oneday = [NSDate date];
    }
    
    NSString *dateFormat = @"yyyy/MM/dd";
    NSString *dateString = [oneday convertToStringWithFormat:dateFormat];
    [self listFilesWithDeviceID:deviceID dateString:dateString completion:completion];
}

- (void)listFilesWithDeviceID:(NSString *)deviceID onemonth:(NSDate * _Nullable)onemonth completion:(void (^)(NSDictionary<NSString *, NSArray<AWSS3Object *> *> *files))completion {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil.");

        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    if (onemonth == nil) {
        onemonth = [NSDate date];
    }
    
    NSString *dateFormat = @"yyyy/MM";
    NSString *dateString = [onemonth convertToStringWithFormat:dateFormat];
    WEAK_SELF(self);
    [self listFilesWithDeviceID:deviceID dateString:dateString completion:^(NSArray<AWSS3Object *> * _Nullable files, NSError * _Nullable error) {
        if (error == nil || files != nil) {
            NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
            [files enumerateObjectsUsingBlock:^(AWSS3Object * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHS3DirectoryInfo *deviceDirectoryInfo = weakself.deviceDirectoryInfos[deviceID];
                NSString *prefix = deviceDirectoryInfo.files;
                NSString *temp = obj.key.stringByDeletingLastPathComponent;
                NSUInteger loc = prefix.length + 1;
                NSString *key = [obj.key substringWithRange:NSMakeRange(loc, temp.length - loc)];
                if (tempDict[key] != nil) {
                    [tempDict[key] addObject:obj];
                } else {
                    tempDict[key] = [NSMutableArray arrayWithObject:obj];
                }
            }];
            
            if (completion) {
                completion(tempDict.copy);
            }
        } else {
            if (completion) {
                completion(nil);
            }
        }
    }];
}

- (void)listFilesWithDeviceID:(NSString *)deviceID startDate:(NSDate *)startDate endDate:(NSDate *)endDate completion:(SHEListFilesCompletionBlock)completion {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil.");

        if (completion) {
            completion(nil, [self createInvalidParametersErrorWithDescription:@"Parameter `deviceID` can't be nil."]);
        }
        
        return;
    }
    
    NSString *dateFormat = @"yyyy/MM/dd";
    NSString *dateString = [[NSDate date] convertToStringWithFormat:dateFormat];
    
    if (startDate != nil && endDate != nil) {
        NSComparisonResult result = [startDate compare:endDate];
        
        if (result == NSOrderedDescending) {
            if (completion) {
                completion(nil, [self createInvalidParametersErrorWithDescription:@"`startDate' should be before the `endDate`."]);
            }
        } else if (result == NSOrderedSame) {
            dateString = [endDate convertToStringWithFormat:dateFormat];
            [self listFilesWithDeviceID:deviceID dateString:dateString completion:completion];
        } else {
            
        }
    } else {
        if (startDate != nil && endDate == nil) {
            dateString = [startDate convertToStringWithFormat:dateFormat];
        } else if (startDate == nil && endDate != nil) {
            dateString = [endDate convertToStringWithFormat:dateFormat];
        }
        
        [self listFilesWithDeviceID:deviceID dateString:dateString completion:completion];
    }
}

- (void)listFilesWithDeviceID:(NSString *)deviceID dateString:(NSString *)dateString completion:(SHEListFilesCompletionBlock)completion {
    if (deviceID.length == 0 || dateString.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` or `dateString` can't be nil.");
        
        if (completion) {
            completion(nil, [self createInvalidParametersErrorWithDescription:@"Paramete `deviceID` or `dateString` can't be nil."]);
        }
        
        return;
    }
    
    if (self.deviceDirectoryInfos[deviceID] == nil) {
        WEAK_SELF(self);
        [self getDeviceS3DirectoryInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                weakself.deviceDirectoryInfos[deviceID] = result;
                
                [weakself listFilesWithDeviceID:deviceID dateString:dateString completion:completion];
            } else {
                if (completion) {
//                    completion(isSuccess, result);
                    if ([result isKindOfClass:[NSError class]]) {
                        completion(nil, result);
                    } else {
                        completion(nil, [weakself createInvalidParametersErrorWithDescription:result]);
                    }
                }
            }
        }];
    } else {
        SHS3DirectoryInfo *deviceDirectoryInfo = self.deviceDirectoryInfos[deviceID];
        NSString *prefix = [deviceDirectoryInfo.files stringByAppendingPathComponent:dateString];
        
        [self listFilesWithDeviceID:deviceID bucketName:deviceDirectoryInfo.bucket prefix:prefix completion:completion];
    }
}

- (void)listFilesWithDeviceID:(NSString *)deviceID bucketName:(NSString *)bucketName prefix:(NSString *)prefix completion:(SHEListFilesCompletionBlock)completion {
    NSString *key = deviceID;
    AWSS3 *s3 = [AWSS3 S3ForKey:key];
    if (s3 == nil) {
        WEAK_SELF(self);
        [self getDeviceIdentityInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                SHIdentityInfo *info = result;
                
                [weakself registerS3WithProviderType:SHES3ProviderTypeDevice identityPoolId:info.IdentityPoolId forKey:key];
                
                [weakself listFilesWithDeviceID:key bucketName:bucketName prefix:prefix completion:completion];
            } else {
                if (completion) {
//                    completion(isSuccess, result);
                    if ([result isKindOfClass:[NSError class]]) {
                        completion(nil, result);
                    } else {
                        completion(nil, [weakself createInvalidParametersErrorWithDescription:result]);
                    }
                }
            }
        }];
    } else {
//        [self listObjectsWithAWSS3Client:s3 bucketName:bucketName prefix:prefix completion:^(BOOL isSuccess, id  _Nullable result) {
//            if (completion) {
//                isSuccess ? completion(isSuccess, ((AWSS3ListObjectsV2Output *)result).contents) : completion(isSuccess, result);
//            }
//        }];
        [self listObjectsWithAWSS3Client:s3 bucketName:bucketName prefix:prefix completion:^(AWSS3ListObjectsV2Output * _Nullable result, NSError * _Nullable error) {
            if (completion) {
                completion(result.contents, error);
            }
        }];
    }
}

#pragma mark - Get File
- (void)getFileWithDeviceID:(NSString *)deviceID s3Object:(AWSS3Object *)s3Obj completion:(SHERequestCompletionBlock)completion {
    if (deviceID.length == 0 || s3Obj == nil) {
        SHLogError(SHLogTagAPP, @"Parameter `deviceID` or `s3Obj` can't be nil.");
        if (completion) {
            completion(NO, @"Parameter `deviceID` or `s3Obj` can't be nil.");
        }
        
        return;
    }
    
    if (self.deviceDirectoryInfos[deviceID] == nil) {
        WEAK_SELF(self);
        [self getDeviceS3DirectoryInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                weakself.deviceDirectoryInfos[deviceID] = result;
                
                [weakself getFileWithDeviceID:deviceID s3Object:s3Obj completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        SHS3DirectoryInfo *deviceDirectoryInfo = self.deviceDirectoryInfos[deviceID];
        
        [self getFileWithDeviceID:deviceID s3Object:s3Obj bucketName:deviceDirectoryInfo.bucket completion:completion];
    }
}

- (void)getFileWithDeviceID:(NSString *)deviceID s3Object:(AWSS3Object *)s3Obj bucketName:(NSString *)bucketName completion:(SHERequestCompletionBlock)completion {
    NSString *key = deviceID;
    AWSS3 *s3 = [AWSS3 S3ForKey:key];
    if (s3 == nil) {
        WEAK_SELF(self);
        [self getDeviceIdentityInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                SHIdentityInfo *info = result;
                
                [weakself registerS3WithProviderType:SHES3ProviderTypeDevice identityPoolId:info.IdentityPoolId forKey:key];
                
                [weakself getFileWithDeviceID:deviceID s3Object:s3Obj bucketName:bucketName completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        [self getObjectWithAWSS3Client:s3 bucketName:bucketName filePath:s3Obj.key completion:completion];
    }
}

- (void)getFilesStorageInfoWithDeviceID:(NSString *)deviceID queryDate:(NSDate *)queryDate days:(NSInteger)days completion:(void (^)(NSDictionary<NSString *, NSNumber *> *))completion {
    if (deviceID.length == 0 || days < 1) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil, or days must be greater than `1`");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    if (queryDate == nil) {
        queryDate = [NSDate date];
    }
    
    NSString *dateFormat = @"yyyy/MM/dd";
    NSString *dateString = [[NSDate date] convertToStringWithFormat:dateFormat];
    
    int beforeDay = 0;
    NSDate *curDate = nil;
    NSString *monthKey = nil;
    NSArray<NSString *> *monthFilesInfo = nil;
    NSDictionary<NSString *, NSArray *> *monthsInfo = nil;
    
    while (days > beforeDay) {
        curDate = [NSDate dateWithTimeInterval:- (beforeDay * 24 * 3600) sinceDate:queryDate];
        monthKey = [self getCurMonthString:curDate];
        
        beforeDay++;
        monthFilesInfo = monthsInfo[monthKey];
        if (monthsInfo == nil) {
            
        }
    }

}

- (NSString *)getCurMonthString:(NSDate *)date {
    NSString *dateFormat = @"yyyy/MM";
    return [date convertToStringWithFormat:dateFormat];
}

@end
