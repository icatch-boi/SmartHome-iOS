//
//  NSString+Convert.h
//  SmartHome
//
//  Created by ZJ on 2017/8/8.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Convert)

/**
 Convert string to lowercase

 @return lowercase
 */
- (NSString *)convertToLowercasee;


/**
 Convert string to caps

 @return caps
 */
- (NSString *)convertToCaps;


/**
 Convert string to uppercase

 @return uppercase
 */
- (NSString *)convertToUppercase;


/**
 Convert string to date

 @param format dateformat
 @return date
 */
- (NSDate *)convertToDateWithFormat:(NSString *)format;

+ (NSString *)translateSecsToString:(NSUInteger)secs;
+ (NSString *)translateSecsToString1:(NSUInteger)secs;

@end
