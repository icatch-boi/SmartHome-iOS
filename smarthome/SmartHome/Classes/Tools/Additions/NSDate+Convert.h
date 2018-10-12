//
//  NSString+TranslateSecs.h
//  SmartHome
//
//  Created by ZJ on 2017/8/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Convert)

/**
 convert date to string

 @param format dateformat
 @return string
 */
- (NSString *)convertToStringWithFormat:(NSString *)format;

@end
