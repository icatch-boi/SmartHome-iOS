//
//  SHQRManager.m
//  SmartHome
//
//  Created by ZJ on 2018/1/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHQRManager.h"
#include <memory.h>

@implementation SHQRManager

+ (instancetype)sharedQRManager {
    static SHQRManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (NSString *)getTokenFromQRString:(NSString *)qrString parseResult:(int *)result {
    if (qrString == nil) {
        SHLogError(SHLogTagAPP, @"qrString is nil");
        return nil;
    }
    
    string  token;
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();
    
    int retVal = qrCrypto->getTokenFromQRString(qrString.UTF8String, token);
    if (retVal == ICH_SUCCEED) {
        SHLogInfo(SHLogTagAPP, "token : %@", [NSString stringWithFormat:@"%s", token.c_str()]);
        return [NSString stringWithFormat:@"%s", token.c_str()];
    } else {
        SHLogError(SHLogTagSDK, @"getTokenFromQRString failed, ret: %d", retVal);
        *result = retVal;
        return nil;
    }
}

- (NSString *)getQRStringToSharing:(NSString *)token authority:(NSString *)authorityDeadline qrDeadline:(NSString *)qrDeadline {
    if (token == nil || authorityDeadline == nil || qrDeadline == nil) {
        SHLogError(SHLogTagAPP, @"token or authorityDeadline or qrDeadline is nil");
        return nil;
    }
    
    string qrString;
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();

    int retVal = qrCrypto->getQrStringToSharing(token.UTF8String, authorityDeadline.UTF8String, qrDeadline.UTF8String, qrString);
    if (retVal == ICH_SUCCEED) {
        return [NSString stringWithFormat:@"%s", qrString.c_str()];
    } else {
        SHLogError(SHLogTagSDK, @"getQRStringToSharing failed, ret: %d", retVal);
        return nil;
    }
}

- (BOOL)permissionsCamera:(NSString *)token {
    if (token == nil) {
        SHLogError(SHLogTagAPP, @"token is nil");
        return NO;
    }
    
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();

    return qrCrypto->permissionsCamera(token.UTF8String);
}

- (BOOL)isAdmin:(NSString *)token {
    if (token == nil) {
        SHLogError(SHLogTagAPP, @"token is nil");
        return NO;
    }
    
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();

    return qrCrypto->isAdmin(token.UTF8String);
}

- (NSString *)getUIDToken:(NSString *)token {
    if (token == nil) {
        SHLogError(SHLogTagAPP, @"token is nil");
        return nil;
    }
    
    string uidToken;
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();

    if (qrCrypto->getUUIDToken(token.UTF8String, uidToken)) {
        SHLogInfo(SHLogTagAPP, "uidToken : %@", [NSString stringWithFormat:@"%s", uidToken.c_str()]);
        return [NSString stringWithFormat:@"%s", uidToken.c_str()];
    } else {
        SHLogWarn(SHLogTagSDK, @"No permission.");
        return nil;
    }
}

- (NSString *)getUID:(NSString *)token {
    if (token == nil) {
        SHLogError(SHLogTagAPP, @"token is nil");
        return nil;
    }
    
    string uid;
    shared_ptr<QRCrypto> qrCrypto = make_shared<QRCrypto>();

    if (qrCrypto->getUUID(token.UTF8String, uid)) {
        return [NSString stringWithFormat:@"%s", uid.c_str()];
    } else {
        SHLogWarn(SHLogTagSDK, @"No permission.");
        return nil;
    }
}

@end
