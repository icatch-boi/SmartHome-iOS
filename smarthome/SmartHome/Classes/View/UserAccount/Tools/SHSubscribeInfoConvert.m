// SHSubscribeInfoConvert.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by sa on 2018/5/11 上午11:04.
    

#import "SHSubscribeInfoConvert.h"
#import "SubscribeStatus.h"
NSString *comment1 = @"通过APP主动邀请正在订阅中的用户";
NSString *comment2 = @"通过APP主动邀请订阅已过期的用户";
NSString *comment3 = @"通过APP主动邀请等待用户确认中";

NSString *comment4 = @"通过APP主动申请访问xx设备的用户已经订阅";
NSString *comment5 = @"通过APP主动申请访问xx设备的用户订阅已过期";
NSString *comment6 = @"通过APP主动申请访问xx设备的用户等待你确认";

NSString *comment7 = @"通过APP主动移除订阅xx设备的用户";
NSString *comment8 = @"通过APP主动移除订阅xx设备已过期的用户";
NSString *comment9 = @"通过APP主动移除订阅xx设备等待确认的用户";

NSString *comment10 = @"订阅xx设备的用户通过APP主动取消订阅";
NSString *comment11 = @"订阅xx设备到期后通过APP主动取消订阅";
NSString *comment12 = @"通过APP拒绝订阅xx设备的用户";


NSString *statuCodeToString(int code)
{
    switch (code) {
        case APP_HOST_SUBSCRIBING:
            return comment1;
            
        case APP_HOST_SUBSCRIBE_INVLID:
            return comment2;
            
        case APP_HOST_WAIT_USER_CONFIRM:
            return comment3;
            
        case APP_USER_SUBSCRIBING:
            return comment4;
            
        case APP_USER_SUBSCRIBE_INVLID:
            return comment5;
            
        case APP_USER_WAIT_HOST_CONFIRM:
            return comment6;
            
        case APP_HOST_REMOVE_USER:
            return comment7;
            
        case APP_HOST_REMOVE_USER_INVALID:
            return comment8;
            
        case APP_HOST_REMOVE_NO_CONFIRM_USER:
            return comment9;
            
        case APP_USER_REMOVE_SUBSCRIBE:
            return comment10;
           
        case APP_USER_REMOVE_INVALID_SUBSCRIBE:
            return comment11;
            
        case APP_USER_REMOVE_REFUSE_SUBSCRIBE:
            return comment12;
  
        default:
            break;
    }
    return [NSString stringWithFormat:@""];
}
