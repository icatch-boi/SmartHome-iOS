//
//  Common.m
//  SmartHome
//
//  Created by ZJ on 2018/3/16.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHUserAccountCommon.h"

@implementation SHUserAccountCommon

+ (NSString *)dateTransformFromString:(NSString *)originalDateStr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:kOriginalDateFormat];
    NSDate *originalDate = [formatter dateFromString:originalDateStr];
    
    // 获取当前时区与0时区的间隔秒数
    NSTimeZone *localZone = [NSTimeZone localTimeZone];
    NSInteger seconds= [localZone secondsFromGMT];
    originalDate = [NSDate dateWithTimeIntervalSince1970:originalDate.timeIntervalSince1970 + seconds/*8.0 * 3600*/];
    
    [formatter setDateFormat:kCurrentDateFormat];
    
    return [formatter stringFromDate:originalDate];
}

+ (NSTimeInterval)timeIntervalString:(NSString *)originalDateStr {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateFormat:kOriginalDateFormat];
    NSDate *originalDate = [formatter dateFromString:originalDateStr];
    
    return originalDate.timeIntervalSince1970;
}

@end
