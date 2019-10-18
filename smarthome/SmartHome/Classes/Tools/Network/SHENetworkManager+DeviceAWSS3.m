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
    [self listFilesWithDeviceID:deviceID dateString:dateString completion:^(AWSS3ListObjectsV2Output * _Nullable result, NSError * _Nullable error) {
        NSArray<AWSS3Object *> * _Nullable files = result.contents;
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
    [self listFilesWithDeviceID:deviceID dateString:dateString startKey:nil number:0 completion:completion];
}

- (void)listFilesWithDeviceID:(NSString *)deviceID dateString:(NSString *)dateString startKey:(NSString * _Nullable)startKey number:(NSInteger)number completion:(SHEListFilesCompletionBlock)completion {
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
                
                [weakself listFilesWithDeviceID:deviceID dateString:dateString startKey:startKey number:number completion:completion];
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
        
        [self listFilesWithDeviceID:deviceID bucketName:deviceDirectoryInfo.bucket prefix:prefix startKey:startKey number:number completion:completion];
    }
}

- (void)listFilesWithDeviceID:(NSString *)deviceID bucketName:(NSString *)bucketName prefix:(NSString *)prefix startKey:(NSString * _Nullable)startKey number:(NSInteger)number completion:(SHEListFilesCompletionBlock)completion {
    NSString *key = deviceID;
    AWSS3 *s3 = [AWSS3 S3ForKey:key];
    if (s3 == nil) {
        WEAK_SELF(self);
        [self getDeviceIdentityInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                SHIdentityInfo *info = result;
                
                [weakself registerS3WithProviderType:SHES3ProviderTypeDevice identityPoolId:info.IdentityPoolId forKey:key];
                
                [weakself listFilesWithDeviceID:key bucketName:bucketName prefix:prefix startKey:startKey number:number completion:completion];
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
        [self listObjectsWithAWSS3Client:s3 bucketName:bucketName prefix:prefix startKey:startKey number:number completion:completion];
    }
}

#pragma mark - Get File
- (void)getFileWithDeviceID:(NSString *)deviceID filePath:(NSString *)filePath completion:(SHERequestCompletionBlock)completion {
    if (deviceID.length == 0 || filePath.length == 0) {
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
                
                [weakself getFileWithDeviceID:deviceID filePath:filePath completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        SHS3DirectoryInfo *deviceDirectoryInfo = self.deviceDirectoryInfos[deviceID];
        
        [self getFileWithDeviceID:deviceID filePath:filePath bucketName:deviceDirectoryInfo.bucket completion:completion];
    }
}

- (void)getFileWithDeviceID:(NSString *)deviceID filePath:(NSString *)filePath bucketName:(NSString *)bucketName completion:(SHERequestCompletionBlock)completion {
    NSString *key = deviceID;
    AWSS3 *s3 = [AWSS3 S3ForKey:key];
    if (s3 == nil) {
        WEAK_SELF(self);
        [self getDeviceIdentityInfoWithDeviceid:deviceID completion:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                SHIdentityInfo *info = result;
                
                [weakself registerS3WithProviderType:SHES3ProviderTypeDevice identityPoolId:info.IdentityPoolId forKey:key];
                
                [weakself getFileWithDeviceID:deviceID filePath:filePath bucketName:bucketName completion:completion];
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

#pragma mark - Files Ops
- (NSDictionary<NSString *, NSNumber *> *)getFilesStorageInfoWithDeviceID:(NSString *)deviceID queryDate:(NSDate *)queryDate days:(NSInteger)days {
    if (deviceID.length == 0 || days < 1) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil, and days must be greater than or equal `1`");
        
        return nil;
    }
    
    if (queryDate == nil) {
        queryDate = [NSDate date];
    }
    
    int beforeDay = 0;
    NSDate *curDate = nil;
    NSString *monthKey = nil;
    NSString *dayKey = nil;
    __block AWSS3ListObjectsV2Output *monthFilesInfo = nil;
    NSMutableDictionary<NSString *, AWSS3ListObjectsV2Output *> *monthsFielsInfo = [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSNumber *> *dayFilesInfo = [NSMutableDictionary dictionary];
    
    while (days > beforeDay) {
        curDate = [NSDate dateWithTimeInterval:- (beforeDay * 24 * 3600) sinceDate:queryDate];
        monthKey = [self getCurMonthString:curDate];
        dayKey = [self getCurDayString:curDate];
        
        beforeDay++;
        monthFilesInfo = monthsFielsInfo[monthKey];
        if (monthFilesInfo == nil) {
            monthFilesInfo = [self getMonthFilesStorageInfoWithDeviceID:deviceID queryDate:curDate];
            
            if (monthFilesInfo != nil) {
                monthsFielsInfo[monthKey] = monthFilesInfo;
            }
        }
        
        if (monthFilesInfo == nil) {
            dayFilesInfo[dayKey] = @(NO);
            continue;
        }
        
        if ([self dayFilesExistWithDeviceID:deviceID dateString:dayKey monthFilesInfos:monthFilesInfo.commonPrefixes]) {
            dayFilesInfo[dayKey] = @(YES);
        } else {
            dayFilesInfo[dayKey] = @(NO);
        }
    }

    return dayFilesInfo.copy;
}

- (BOOL)dayFilesExistWithDeviceID:(NSString *)deviceID dateString:(NSString *)dateString monthFilesInfos:(NSArray<AWSS3CommonPrefix *> *)monthFilesInfos {
    __block BOOL exist = NO;
    
    SHS3DirectoryInfo *deviceDirectoryInfo = self.deviceDirectoryInfos[deviceID];
    NSString *prefix = [deviceDirectoryInfo.files stringByAppendingPathComponent:dateString];
    prefix = [prefix stringByAppendingString:@"/"];
    
    [monthFilesInfos enumerateObjectsUsingBlock:^(AWSS3CommonPrefix * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.prefix isEqualToString:prefix]) {
            exist = YES;
            *stop = YES;
        }
    }];
    
    return exist;
}

- (NSString *)getCurDayString:(NSDate *)date {
    NSString *dateFormat = @"yyyy/MM/dd";
    return [date convertToStringWithFormat:dateFormat];
}

- (NSString *)getCurMonthString:(NSDate *)date {
    NSString *dateFormat = @"yyyy/MM";
    return [date convertToStringWithFormat:dateFormat];
}

- (AWSS3ListObjectsV2Output * _Nullable)getMonthFilesStorageInfoWithDeviceID:(NSString *)deviceID queryDate:(NSDate *)queryDate {
    __block AWSS3ListObjectsV2Output *monthFilesInfo = nil;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    [self getMonthFilesStorageInfoWithDeviceID:deviceID queryDate:queryDate completion:^(AWSS3ListObjectsV2Output * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
            monthFilesInfo = result;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return monthFilesInfo;
}

- (void)getMonthFilesStorageInfoWithDeviceID:(NSString *)deviceID queryDate:(NSDate *)queryDate completion:(SHEListFilesCompletionBlock)completion {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Parameter `deviceID` can't be nil.");
        
        if (completion) {
            completion(nil, [self createInvalidParametersErrorWithDescription:@"Parameter `deviceID` can't be nil."]);
        }
        
        return;
    }
    
    if (queryDate == nil) {
        queryDate = [NSDate date];
    }
    
    NSString *dateFormat = @"yyyy/MM";
    NSString *dateString = [queryDate convertToStringWithFormat:dateFormat];

    [self listFilesWithDeviceID:deviceID dateString:dateString completion:completion];
}

- (void)listFilesWithDeviceID:(NSString *)deviceID queryDate:(NSDate *)queryDate startKey:(NSString * _Nullable)startKey number:(NSInteger)number completion:(void (^)(NSArray<SHS3FileInfo *> * _Nullable filesInfo))completion {
    if (deviceID.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` can't be nil.");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    if (queryDate == nil) {
        queryDate = [NSDate date];
    }
    
    NSString *dateFormat = @"yyyy/MM/dd";
    NSString *dateString = [queryDate convertToStringWithFormat:dateFormat];
    
    WEAK_SELF(self);
    [self listFilesWithDeviceID:deviceID dateString:dateString startKey:startKey number:number completion:^(AWSS3ListObjectsV2Output * _Nullable result, NSError * _Nullable error) {
        if (error == nil) {
            NSArray<AWSS3Object *> *contents = result.contents;
            
            if (contents == nil) {
                if (completion) {
                    completion(nil);
                }
                
                return;
            }
            
            [weakself getFilesInfoWithDeviceID:deviceID fileContents:contents completion:completion];
        } else {
            SHLogError(SHLogTagAPP, @"List files failed, error: %@", error);
            
            if (completion) {
                completion(nil);
            }
        }
    }];
}

- (void)getFilesInfoWithDeviceID:(NSString *)deviceID fileContents:(NSArray<AWSS3Object *> *)contents completion:(void (^)(NSArray<SHS3FileInfo *> * _Nullable filesInfo))completion {
    if (deviceID.length == 0 || contents.count == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` or `contents` can't be nil.");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.icatchtek.GetFilesInfo", DISPATCH_QUEUE_CONCURRENT);
    
    NSMutableArray<SHS3FileInfo *> *infoArray = [NSMutableArray array];
    
    [contents enumerateObjectsUsingBlock:^(AWSS3Object * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *key = obj.key;
        if ([key hasSuffix:@".jpg"] || [key hasSuffix:@".JPG"]) {
            NSString *videoPath = [self getVideoPathWithFileContents:contents key:key];
            if (videoPath != nil) {
                dispatch_group_enter(group);
                dispatch_async(queue, ^{
                    [self getFileInfoWithDeviceID:deviceID filePath:key completion:^(SHS3FileInfo * _Nullable fileInfo) {
                        if (fileInfo != nil) {
                            fileInfo.filePath = videoPath;
                            fileInfo.key = key;
                            fileInfo.fileName = [[videoPath componentsSeparatedByString:@"/"] lastObject];
                            
                            [infoArray addObject:fileInfo];
                        }
                        
                        dispatch_group_leave(group);
                    }];
                });
            }
        }
    }];
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        SHLogInfo(SHLogTagAPP, @"Files count: %lu", (unsigned long)infoArray.count);

        if (completion) {
            completion(infoArray.copy);
        }
    });
}

- (void)getFileInfoWithDeviceID:(NSString *)deviceID filePath:(NSString *)filePath completion:(void (^)(SHS3FileInfo * _Nullable fileInfo))completion {
    if (deviceID.length == 0 || filePath.length == 0) {
        SHLogError(SHLogTagAPP, @"Paramete `deviceID` or `fileName` can't be nil.");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    [self getFileWithDeviceID:deviceID filePath:filePath completion:^(BOOL isSuccess, id  _Nullable result) {
        SHS3FileInfo *fileInfo = nil;
        
        if (isSuccess == YES) {
            AWSS3GetObjectOutput *response = result;
            NSDictionary<NSString *, NSString *> *metadata = response.metadata;
            
            if (metadata != nil) {
                fileInfo = [SHS3FileInfo s3FileInfoWithFileInfoDict:metadata];
            }
            
            if (fileInfo != nil) {
                fileInfo.thumbnail = [[UIImage alloc] initWithData:response.body];
            }
        } else {
            SHLogError(SHLogTagAPP, @"Get file failed, error: %@", result);
        }
        
        if (completion) {
            completion(fileInfo);
        }
    }];
}

- (NSString *)getVideoPathWithFileContents:(NSArray<AWSS3Object *> *)contents key:(NSString *)key {
    if (contents.count == 0 || key.length == 0) {
        SHLogWarn(SHLogTagAPP, @"Paramete `contents` or `key` can't be nil.");
        return nil;
    }
    
    NSString *videoKeyHeader = [key componentsSeparatedByString:@"."][0];
    __block NSString *videoKey = nil;
    
    [contents enumerateObjectsUsingBlock:^(AWSS3Object * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tempKey = obj.key;

        if (![tempKey isEqualToString:key] && [tempKey hasPrefix:videoKeyHeader]) {
            videoKey = tempKey;
            *stop = YES;
        }
    }];
    
    return videoKey;
}

@end
