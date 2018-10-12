//
//  NSString+TranslateSecs.m
//  SmartHome
//
//  Created by ZJ on 2017/8/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "NSDate+Convert.h"

@implementation NSDate (Convert)

- (NSString *)convertToStringWithFormat:(NSString *)format {
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:format];
    return [dateformatter stringFromDate:self];
}

@end
