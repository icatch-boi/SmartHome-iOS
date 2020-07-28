// SHMessageCountManager.m

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
 
 // Created by zj on 2019/8/22 3:17 PM.
    

#import "SHMessageCountManager.h"

@implementation SHMessageCountManager

+ (void)updateMessageCountCacheWithCameraObj:(SHCameraObject *)camObj {
    if (camObj == nil || camObj.camera.cameraUid.length == 0) {
        NSLog(@"Camera obj or camera uid is nil.");
        return;
    }
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *local = [defaults objectForKey:kRecvNotificationCount];
    
    NSString *uid = camObj.camera.cameraUid;
    NSUInteger currentNum = camObj.newMessageCount;
    
    NSMutableDictionary *current;
    if (local == nil) {
        current = [[NSMutableDictionary alloc] init];
    } else {
        if ([local.allKeys containsObject:uid]) {
            NSUInteger preNum = [local[uid] unsignedIntegerValue];
            
            if (preNum == currentNum) {
                return;
            }
        }
        
        current = [[NSMutableDictionary alloc] initWithDictionary:local];
    }
    
    current[uid] = @(currentNum);
    [defaults setObject:current.copy forKey:kRecvNotificationCount];
}

+ (void)removeMessageCountCacheWithCameraUID:(NSString *)uid {
    if (uid.length == 0) {
        NSLog(@"uid is nil.");
        return;
    }
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *local = [defaults objectForKey:kRecvNotificationCount];
    
    if (local != nil) {
        if ([local.allKeys containsObject:uid]) {
            NSMutableDictionary *current = [[NSMutableDictionary alloc] initWithDictionary:local];
            [current removeObjectForKey:uid];
            
            [defaults setObject:current.copy forKey:kRecvNotificationCount];
        }
    }
}

@end
