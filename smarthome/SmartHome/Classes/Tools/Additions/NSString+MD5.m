// NSString+MD5.m

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
 
 // Created by zj on 2018/4/4 下午2:00.
    

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>

//秘钥
static NSString * const encryptionKey = @"nha735n197nxn(N′568GGS%d~~9naei';45vhhafdjkv]32rpks;lg,];:vjo(&**&^)";

@implementation NSString (MD5)

- (NSString *)md5Encrypt {
    return [[NSString stringWithFormat:@"%@%@", encryptionKey, self] md5];
}

- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char digest[kMD5DigestLength];
    
    CC_MD5(cStr, (CC_LONG)strlen(cStr), digest);
    
    NSMutableString *result = [NSMutableString stringWithCapacity:kMD5DigestLength * 2];
    for (int i = 0; i < kMD5DigestLength; i++) {
        [result appendFormat:@"%02X", digest[i]];
    }
    
    return result;
}

@end
