// TimeHelper.m

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
 
 // Created by sa on 2018/3/30 下午5:39.
    

#import "TimeHelper.h"
static NSString *innerFormat = @"yyyy-MM-dd HH:mm:ss";
static NSString *outterFormat = @"yyyy/MM/dd HH:mm:ss";
static NSString *innerDateFormat = @"yyyy-MM-dd";
static NSString *innerTimeFormat = @"HH:mm:ss";

@implementation TimeHelper
+ (NSString *)innerFormatToOutterFormat:(NSString *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:innerFormat];
    NSDate *date = [df dateFromString:datetime];
    
    [df setDateFormat:outterFormat];
    return [df stringFromDate:date];
}

+ (NSString *)outterFormatToInnerFormat:(NSString *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:outterFormat];
    NSDate *date = [df dateFromString:datetime];
    
    [df setDateFormat:innerFormat];
    return [df stringFromDate:date];
}

+ (NSDate *)getDatetimeFromString:(NSString *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:innerFormat];
    return [df dateFromString:datetime];
}

+ (NSString *)getDateTimeStringFromDate:(NSDate *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:innerFormat];
    return [df stringFromDate:datetime];
}

+ (NSString *)getDateWithString:(NSString *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:innerFormat];
    NSDate *date = [df dateFromString:datetime];
    [df setDateFormat:innerDateFormat];
    return [df stringFromDate:date];
}

+ (NSString *)getTimeWithString:(NSString *)datetime
{
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:innerFormat];
    NSDate *date = [df dateFromString:datetime];
    [df setDateFormat:innerTimeFormat];
    return [df stringFromDate:date];
}

@end
