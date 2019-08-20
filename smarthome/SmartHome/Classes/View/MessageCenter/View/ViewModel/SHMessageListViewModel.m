// SHMessageListViewModel.m

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
 
 // Created by zj on 2019/7/26 5:00 PM.
    

#import "SHMessageListViewModel.h"
#import "SHNetworkManager+SHCamera.h"
#import "SHMessageInfo.h"

static const NSInteger maxPullupTryTimes = 3;

@interface SHMessageListViewModel ()

@property (nonatomic, strong) NSMutableArray<SHMessageInfo *> *messageList;
@property (nonatomic, copy) NSNumber *lastquerykey;
@property (nonatomic, assign) NSInteger pullupErrorTimes;

@end

@implementation SHMessageListViewModel

- (void)loadMessageWithCamera:(SHCamera *)camera pullup:(BOOL)pullup completion:(void (^)(BOOL isSuccess, BOOL shouldRefresh))completion {
    
    if (pullup && self.pullupErrorTimes > maxPullupTryTimes) {
        if (completion) {
            completion(YES, NO);
        }
        
        return;
    }
    
    NSNumber *sinceid = pullup ? _lastquerykey : nil;
    NSString *enddate = pullup ? [self serverDateStringFromLocal:camera.createTime] : self.messageList.firstObject.time;
    
    [[SHNetworkManager sharedNetworkManager] getDeviceMessageWithDeviceID:camera.id sinceid:sinceid enddate:enddate completion:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess == NO) {
            if (completion) {
                completion(isSuccess, NO);
            }
            
            return;
        }
        
        NSDictionary *dict = result;
        if (![dict.allKeys containsObject:@"messages"]) {
            if (completion) {
                completion(isSuccess, NO);
            }
        } else {
            NSArray *recv = result[@"messages"];
            NSMutableArray *temp = [NSMutableArray arrayWithCapacity:10];
            [recv enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                SHMessageInfo *msgInfo = [SHMessageInfo messageInfoWithDict:obj];
                msgInfo.deviceID = camera.id;
                [temp addObject:msgInfo];
            }];
            
            SHLogInfo(SHLogTagAPP, @"刷新到: %d 条数据", temp.count);
            
            if (temp.count <= 0) {
                if (completion) {
                    completion(isSuccess, NO);
                }
                
                return;
            }
            
            if (pullup) {
                [self.messageList addObjectsFromArray:temp.copy];
            } else {
                if ([result containsObject:@"lastquerykey"]) {
                    [self.messageList removeAllObjects];
                    [self.messageList addObjectsFromArray:temp.copy];
                    
                    self.lastquerykey = result[@"lastquerykey"];
                } else {
                    NSIndexSet *idxSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, temp.count)];
                    [self.messageList insertObjects:temp.copy atIndexes:idxSet];
                }
            }
            
            if (pullup && temp.count == 0) {
                self.pullupErrorTimes += 1;
                
                if (completion) {
                    completion(isSuccess, NO);
                }
            } else {
                if (completion) {
                    completion(isSuccess , YES);
                }
            }
        }
    }];
}

- (NSString *)serverDateStringFromLocal:(NSString *)local {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMdd HHmmss"];
    
    NSDate *localDate = [formatter dateFromString:local];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"];

    NSString *serverDate = [formatter stringFromDate:localDate];
    
    return serverDate;
}

- (NSMutableArray<SHMessageInfo *> *)messageList {
    if (_messageList == nil) {
        _messageList = [NSMutableArray array];
    }
    
    return _messageList;
}

@end
