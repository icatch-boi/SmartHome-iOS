//
//  Common.h
//  SmartHome
//
//  Created by ZJ on 2018/3/16.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kOriginalDateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
static NSString * const kCurrentDateFormat = @"yyyy-MM-dd HH:mm:ss";

@interface SHUserAccountCommon : NSObject

+ (NSString *)dateTransformFromString:(NSString *)originalDateStr;
+ (NSTimeInterval)timeIntervalString:(NSString *)originalDateStr;

@end
