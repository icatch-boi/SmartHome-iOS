// SHDeviceAuthenticatedIdentityProvider.m

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
 
 // Created by zj on 2019/9/23 5:52 PM.
    

#import "SHDeviceAuthenticatedIdentityProvider.h"
#import "SHIdentityInfo.h"
#import "SHENetworkManager+DeviceAWSS3.h"

static NSString * const kIdentityProviderName = @"cognito-identity.cn-north-1.amazonaws.com.cn";

@interface SHDeviceAuthenticatedIdentityProvider ()

@property (nonatomic, copy) NSString *deviceID;

@end

@implementation SHDeviceAuthenticatedIdentityProvider

- (instancetype)initWithRegionType:(AWSRegionType)regionType identityPoolId:(NSString *)identityPoolId useEnhancedFlow:(BOOL)useEnhancedFlow identityProviderManager:(nullable id<AWSIdentityProviderManager>)identityProviderManager deviceID:(NSString *)deviceID {
    self = [super initWithRegionType:regionType identityPoolId:identityPoolId useEnhancedFlow:useEnhancedFlow identityProviderManager:identityProviderManager];
    if (self) {
        self.deviceID = deviceID;
    }
    
    return self;
}

- (AWSTask<NSDictionary<NSString *,NSString *> *> *)logins {
    if (self.isAuthenticated) {
        return [super logins];
    }
    
    SHIdentityInfo *info = [[SHENetworkManager sharedManager] getDeviceIdentityInfoWithDeviceid:self.deviceID];
    if (info == nil) {
        return [super logins];
    }
    
    self.identityId = info.IdentityId;
    return [AWSTask taskWithResult: @{kIdentityProviderName: info.Token}];
}

@end
