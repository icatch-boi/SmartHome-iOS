// SHNetworkRequestErrorDes.m

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
 
 // Created by zj on 2018/11/23 1:37 PM.
    

#import "SHNetworkRequestErrorDes.h"

@implementation SHNetworkRequestErrorDes

+ (NSString *)errorDescriptionWithCode:(NSInteger)errorCode {
    id key = @(errorCode);
    
    if ([[self errorDescription].allKeys containsObject:key]) {
        return [[self errorDescription] objectForKey:key];
    }
    
    return @"";
}

+ (NSDictionary *)errorDescription {
    return @{
             @(10001): NSLocalizedString(@"kNetworkRequestError_10001", nil),
             @(10011): NSLocalizedString(@"kNetworkRequestError_10011", nil),
             @(10012): NSLocalizedString(@"kNetworkRequestError_10012", nil),
             @(10013): NSLocalizedString(@"kNetworkRequestError_10013", nil),
             @(10014): NSLocalizedString(@"kNetworkRequestError_10014", nil),
             @(10015): NSLocalizedString(@"kNetworkRequestError_10015", nil),
             @(10041): NSLocalizedString(@"kNetworkRequestError_10041", nil),
             @(10042): NSLocalizedString(@"kNetworkRequestError_10042", nil),
             @(10043): NSLocalizedString(@"kNetworkRequestError_10043", nil),
             @(10044): NSLocalizedString(@"kNetworkRequestError_10044", nil),
             @(10051): NSLocalizedString(@"kNetworkRequestError_10051", nil),
             @(10052): NSLocalizedString(@"kNetworkRequestError_10052", nil),
             @(10061): NSLocalizedString(@"kNetworkRequestError_10061", nil),
             @(20001): NSLocalizedString(@"kNetworkRequestError_20001", nil),
             @(20002): NSLocalizedString(@"kNetworkRequestError_20002", nil),
             @(20003): NSLocalizedString(@"kNetworkRequestError_20003", nil),
             @(20004): NSLocalizedString(@"kNetworkRequestError_20004", nil),
             @(20005): NSLocalizedString(@"kNetworkRequestError_20005", nil),
             @(20011): NSLocalizedString(@"kNetworkRequestError_20011", nil),
             @(20012): NSLocalizedString(@"kNetworkRequestError_20012", nil),
             @(20021): NSLocalizedString(@"kNetworkRequestError_20021", nil),
             @(20022): NSLocalizedString(@"kNetworkRequestError_20022", nil),
             @(20031): NSLocalizedString(@"kNetworkRequestError_20031", nil),
             @(20032): NSLocalizedString(@"kNetworkRequestError_20032", nil),
             @(40001): NSLocalizedString(@"kNetworkRequestError_40001", nil),
             @(40002): NSLocalizedString(@"kNetworkRequestError_40002", nil),
             @(40003): NSLocalizedString(@"kNetworkRequestError_40003", nil),
             @(40022): NSLocalizedString(@"kNetworkRequestError_40022", nil),
             @(40024): NSLocalizedString(@"kNetworkRequestError_40024", nil),
             @(40025): NSLocalizedString(@"kNetworkRequestError_40025", nil),
             @(40026): NSLocalizedString(@"kNetworkRequestError_40026", nil),
             @(40027): NSLocalizedString(@"kNetworkRequestError_40027", nil),
             @(40031): NSLocalizedString(@"kNetworkRequestError_40031", nil),
             @(40034): NSLocalizedString(@"kNetworkRequestError_40034", nil),
             @(40041): NSLocalizedString(@"kNetworkRequestError_40041", nil),
             @(40042): NSLocalizedString(@"kNetworkRequestError_40042", nil),
             @(40043): NSLocalizedString(@"kNetworkRequestError_40043", nil),
             @(40051): NSLocalizedString(@"kNetworkRequestError_40051", nil),
             @(40052): NSLocalizedString(@"kNetworkRequestError_40052", nil),
             @(50001): NSLocalizedString(@"kNetworkRequestError_50001", nil),
             @(50002): NSLocalizedString(@"kNetworkRequestError_50002", nil),
             @(50003): NSLocalizedString(@"kNetworkRequestError_50003", nil),
             @(50004): NSLocalizedString(@"kNetworkRequestError_50004", nil),
             @(50005): NSLocalizedString(@"kNetworkRequestError_50005", nil),
             @(50021): NSLocalizedString(@"kNetworkRequestError_50021", nil),
             @(50022): NSLocalizedString(@"kNetworkRequestError_50022", nil),
             @(50023): NSLocalizedString(@"kNetworkRequestError_50023", nil),
             @(50024): NSLocalizedString(@"kNetworkRequestError_50024", nil),
             @(50025): NSLocalizedString(@"kNetworkRequestError_50025", nil),
             @(50026): NSLocalizedString(@"kNetworkRequestError_50026", nil),
             @(50027): NSLocalizedString(@"kNetworkRequestError_50027", nil),
             @(50033): NSLocalizedString(@"kNetworkRequestError_50033", nil),
             @(50034): NSLocalizedString(@"kNetworkRequestError_50034", nil),
             };
}

@end
