// Message.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2018 by iCatch Technology, Inc.
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
 
 // Created by guo on 12/03/2018 17:18.
    

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property(nonatomic, readonly) NSString * _Nonnull msgId;
@property(nonatomic, readonly) NSInteger msgType;
@property(nonatomic, readonly) NSString * _Nonnull time;
@property(nonatomic, readonly) NSString * _Nonnull fromid;
@property(nonatomic, readonly) NSString * _Nonnull fromname;
@property(nonatomic, readonly) NSInteger status;
@property(nonatomic, readonly) NSString * _Nonnull deviceId;
@property(nonatomic, readonly) NSInteger access;
@property(nonatomic, readonly) NSInteger expires;
@property(nonatomic, readonly) NSString * _Nullable code;

-(instancetype _Nonnull )initWithData:(NSDictionary * _Nonnull )dict;

@end
