// SHMessageFile.m

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
 
 // Created by zj on 2019/8/19 2:59 PM.
    

#import "SHMessageFile.h"
#import "SHNetworkManager+SHCamera.h"

@interface SHMessageFile ()

@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSNumber *expires;

@end

@implementation SHMessageFile

+ (instancetype)messageFileWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

+ (void)getMessageFileWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(nullable MessageFileGetFileCompletion)completion {
    if (fileName.length == 0 || deviceID.length == 0) {
        SHLogWarn(SHLogTagAPP, @"file name or device id is nil.");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    [[SHNetworkManager sharedNetworkManager] getDeviceMessageFileInfoWithDeviceID:deviceID fileName:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"getDeviceMessageFileInfoWithDeviceID is success: %d", isSuccess);
        
        SHMessageFile *messageFile;
        if (isSuccess) {
            messageFile = [SHMessageFile messageFileWithDict:result];
        }
        
        if (completion) {
            completion(messageFile);
        }
    }];
}

@end
