// SHFileInfoViewModel.m

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
 
 // Created by zj on 2019/10/17 3:43 PM.
    

#import "SHFileInfoViewModel.h"
#import "SHENetworkManagerCommon.h"
#import "SHFileCenterCommon.h"

@interface SHFileInfoViewModel ()

@property (nonatomic, copy) NSString *deviceID;

@end

@implementation SHFileInfoViewModel

- (instancetype)initWithDeviceID:(NSString *)deviceID
{
    self = [super init];
    if (self) {
        self.deviceID = deviceID;
    }
    return self;
}

+ (instancetype)fileInfoViewModelWithDeviceID:(NSString *)deviceID {
    return [[self alloc] initWithDeviceID:deviceID];
}

- (void)loadDateFileInfoWithDate:(NSDate *)date completion:(void (^)(NSArray<SHDateFileInfo *> *dateFileInfos))completion {
    WEAK_SELF(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary<NSString *, NSNumber *> *dict = [[SHENetworkManager sharedManager] getFilesStorageInfoWithDeviceID:_deviceID queryDate:date days:kFileCenterShowDays];
        
        NSMutableArray<SHDateFileInfo *> *dateFileInfos = [NSMutableArray arrayWithCapacity:dict.count];
        [dict enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            SHDateFileInfo *info = [[SHDateFileInfo alloc] init];
            info.dateString = key;
            info.exist = [obj boolValue];
            info.deviceID = weakself.deviceID;
            
            [dateFileInfos addObject:info];
        }];
        
        SHLogInfo(SHLogTagAPP, @"Before: %@", dateFileInfos);
        
        [dateFileInfos sortUsingComparator:^NSComparisonResult(SHDateFileInfo *  _Nonnull obj1, SHDateFileInfo *  _Nonnull obj2) {
            return [obj1.dateString compare:obj2.dateString];
        }];
        
        SHLogInfo(SHLogTagAPP, @"After: %@", dateFileInfos);
        
        if (completion) {
            completion(dateFileInfos.copy);
        }
    });
}

@end
