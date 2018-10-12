// BasicVisitInfo.h

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
 
 // Created by sa on 2018/5/9 下午3:43.
    

#import <Foundation/Foundation.h>

@interface BasicVisitInfo : NSObject
@property (nonatomic, readonly) NSString *deviceId;
@property (nonatomic, readonly) NSString *time;
@property (nonatomic, readonly) int count;
@property (nonatomic, readonly) int positon;
-(instancetype)initWithData:(NSDictionary *)dict;
@end
