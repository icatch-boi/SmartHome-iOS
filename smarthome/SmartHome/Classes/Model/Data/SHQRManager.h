//
//  SHQRManager.h
//  SmartHome
//
//  Created by ZJ on 2018/1/8.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHQRManager : NSObject

+ (instancetype)sharedQRManager;
- (instancetype)init __attribute__((unavailable("Disabled. Please use the sharedQRManager methods instead.")));

- (NSString *)getTokenFromQRString:(NSString *)qrString parseResult:(int *)result;
- (NSString *)getQRStringToSharing:(NSString *)token authority:(NSString *)authorityDeadline qrDeadline:(NSString *)qrDeadline;
- (BOOL)permissionsCamera:(NSString *)token;
- (BOOL)isAdmin:(NSString *)token;
- (NSString *)getUIDToken:(NSString *)token;
- (NSString *)getUID:(NSString *)token;

@end
