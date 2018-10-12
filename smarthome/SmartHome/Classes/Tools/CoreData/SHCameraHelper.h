// SHCameraHelper.h

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
 
 // Created by zj on 2018/4/24 下午5:07.
    

#import <Foundation/Foundation.h>

@interface SHCameraHelper : NSObject

@property (nonatomic, copy) NSString *cameraName;
#if USE_ENCRYP
@property (nonatomic, copy) NSString *cameraToken;
@property (nonatomic, copy) NSString *cameraUidToken;
#endif
@property (nonatomic, copy) NSString *cameraUid;
@property (nonatomic, copy) NSString *devicePassword;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, strong) UIImage *thumnail;
@property (nonatomic) int operable;

#if USE_ENCRYP
+ (instancetype)cameraWithName:(NSString *)cameraName
                   cameraToken:(NSString *)cameraToken
                cameraUidToken:(NSString *)cameraUidToken
                devicePassword:(NSString *)devicePassword
                            id:(NSString *)cameraId
                     thumbnail:(UIImage *)thumnail
                      operable:(int)operable;
#else
+ (instancetype)cameraWithName:(NSString *)cameraName
                     cameraUid:(NSString *)cameraUid
                devicePassword:(NSString *)devicePassword
                            id:(NSString *)cameraId
                     thumbnail:(UIImage *)thumnail
                      operable:(int)operable;
#endif

@end
