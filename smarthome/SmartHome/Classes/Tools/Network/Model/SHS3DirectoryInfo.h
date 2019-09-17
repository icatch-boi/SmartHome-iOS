// SHS3DirectoryInfo.h

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
 
 // Created by zj on 2019/9/11 4:44 PM.
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SHS3DirectoryInfo : NSObject

@property (nonatomic, copy, readonly) NSString *bucket;
@property (nonatomic, copy, readonly) NSString *path;
@property (nonatomic, copy, readonly) NSString *portrait;
@property (nonatomic, copy, readonly) NSString *faces;
@property (nonatomic, copy, readonly) NSString *cover;
@property (nonatomic, copy, readonly) NSString *messages;
@property (nonatomic, copy, readonly) NSString *files;

+ (instancetype)s3DirectoryInfoWithDict:(NSDictionary *)dict;
- (NSDictionary *)conversionToDictionary;

@end

NS_ASSUME_NONNULL_END
