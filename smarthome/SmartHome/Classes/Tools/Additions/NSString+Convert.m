//
//  NSString+Convert.m
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "NSString+Convert.h"

@implementation NSString (Convert)

- (NSString *)convertToLowercasee {
    return [self lowercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *)convertToCaps {
    return [self capitalizedStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *)convertToUppercase {
    return [self uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSDate *)convertToDateWithFormat:(NSString *)format {
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:format];
    return [dateformatter dateFromString:self];
}

+ (NSString *)translateSecsToString:(NSUInteger)secs {
    NSString *retVal = nil;
    int tempHour = 0;
    int tempMinute = 0;
    int tempSecond = 0;
    
    NSString *hour = @"";
    NSString *minute = @"";
    NSString *second = @"";
    
    tempHour = (int)(secs / 3600);
    tempMinute = (int)(secs / 60 - tempHour * 60);
    tempSecond = (int)(secs - (tempHour * 3600 + tempMinute * 60));
    
    //hour = [[NSNumber numberWithInt:tempHour] stringValue];
    //minute = [[NSNumber numberWithInt:tempMinute] stringValue];
    //second = [[NSNumber numberWithInt:tempSecond] stringValue];
    hour = [@(tempHour) stringValue];
    minute = [@(tempMinute) stringValue];
    second = [@(tempSecond) stringValue];
    
    if (tempHour < 10) {
        hour = [@"0" stringByAppendingString:hour];
    }
    
    if (tempMinute < 10) {
        minute = [@"0" stringByAppendingString:minute];
    }
    
    if (tempSecond < 10) {
        second = [@"0" stringByAppendingString:second];
    }
    
    retVal = [NSString stringWithFormat:@"%@:%@:%@", hour, minute, second];
    
    return retVal;
}

+ (NSString *)translateSecsToString1:(NSUInteger)secs {
    NSMutableString *retVal = [NSMutableString string];
    int tempHour = 0;
    int tempMinute = 0;
    int tempSecond = 0;
    
    NSString *hour = @"";
    NSString *minute = @"";
    NSString *second = @"";
    
    tempHour = (int)(secs / 3600);
    tempMinute = (int)(secs / 60 - tempHour * 60);
    tempSecond = (int)(secs - (tempHour * 3600 + tempMinute * 60));
    
    hour = [@(tempHour) stringValue];
    minute = [@(tempMinute) stringValue];
    second = [@(tempSecond) stringValue];
    
    if (tempHour > 0) {
        [retVal appendString:[NSString stringWithFormat:@"%@ h ", hour]];
    }
    
    if (tempMinute > 0) {
        [retVal appendString:[NSString stringWithFormat:@"%@ min ", minute]];
    }
    
    if (tempSecond >= 0) {
        [retVal appendString:[NSString stringWithFormat:@"%@ sec", second]];
    }
    
    return retVal;
}

@end
