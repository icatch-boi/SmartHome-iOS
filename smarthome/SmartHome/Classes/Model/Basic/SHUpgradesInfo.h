// SHUpgradesInfo.h

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
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
 
 // Created by zj on 2019/3/13 11:34 AM.
    

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SHUpgradesInfo : NSObject

@property (nonatomic, copy, readonly) NSString *versionid;
@property (nonatomic, copy, readonly) NSString *html_description;
@property (nonatomic, copy, readonly) NSString *expires;
@property (nonatomic, copy, readonly) NSString *time;
@property (nonatomic, copy, readonly) NSNumber *size;
@property (nonatomic, strong, readonly) NSArray<NSString *> *url;
@property (nonatomic, strong, readonly) NSArray<NSString *> *name;

+ (instancetype)upgradesInfoWithDict:(NSDictionary *)dict;
- (instancetype)initWithDict:(NSDictionary *)dict;

+ (void)checkUpgradesWithCameraObj:(SHCameraObject *)shCameraObj completion:(void (^)(BOOL upgrades, SHUpgradesInfo * _Nullable info))completion;

+ (NSAttributedString *)upgradesAlertViewMessageWithInfo:(SHUpgradesInfo *)info;
+ (NSAttributedString *)upgradesAlertViewTitle;

@end

NS_ASSUME_NONNULL_END
