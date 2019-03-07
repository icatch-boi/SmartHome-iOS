// SHNetworkManager+SHPush.m

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
 
 // Created by zj on 2018/10/12 下午2:20.
    

#import "SHNetworkManager+SHPush.h"
#import <AFNetworking/AFNetworking.h>
#import "SHUserAccount.h"

@implementation SHNetworkManager (SHPush)

#pragma mark - ClientInfo
- (void)registerClient:(NSString *)deviceToken finished:(_Nullable RequestCompletionBlock)finished {
    if (deviceToken == nil || deviceToken.length <= 0) {
        if (finished) {
            finished(NO, @"device token is nil.");
        }
        return;
    }
    
    NSString *pushName = @"apns";
#ifdef DEBUG
    pushName = @"apns_dev";
#endif
    NSDictionary *parameters = @{
                                 @"push_name": pushName,
                                 @"push_type": @"ios",
                                 @"push_token": deviceToken,
                                 };
    
    [self pushRequestWithMethod:SHRequestMethodPOST urlString:CLIENT_INFO parametes:parameters finished:finished];
}

- (void)pushMessageWithUID:(NSString *)uid message:(NSString *)message pushType:(SHPushType)pushType finished:(_Nullable RequestCompletionBlock)finished {
    if (uid == nil || uid.length <= 0) {
        if (finished) {
            finished(NO, @"device uid is nil.");
        }
        return;
    }
    
    if (message == nil || message.length <= 0) {
        if (finished) {
            finished(NO, @"message is nil.");
        }
        return;
    }
    
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (finished) {
            finished(YES, responseObject);
        }
    };
    
    id faiure = ^(NSURLSessionDataTask *_Nonnull task, NSError * _Nonnull error) {
        
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        NSDictionary *err = [self parseErrorInfo:error];
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(NO, err);
        }
    };
    
    NSString *baseURL = @"http://www.smarthome.icatchtek.com/messages/topic4?";
    if (pushType == SHPushTypeOther) {
        baseURL = @"http://push.iotcplatform.com/tpns?";
    }
    NSString *urlString = [NSString stringWithFormat:@"%@cmd=event&img=1&uid=%@&msg=%@", baseURL, uid, message];
    if (pushType == SHPushTypeOur) {
        urlString = [NSString stringWithFormat:@"%@cmd=event&appkey=XXXXXXX1C5262CC1&img=1&uid=%@&msg=%@", baseURL, uid, message];
    }
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];

    [manager POST:urlString parameters:nil progress:nil success:success failure:faiure];
}

#pragma mark - Request method
- (void)pushRequestWithMethod:(SHRequestMethod)method urlString:(NSString *)urlString parametes:(id)parametes finished:(RequestCompletionBlock)finished {
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (finished) {
            finished(YES, responseObject);
        }
    };
    
    id failure = ^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 401) {
            SHLogError(SHLogTagAPP, @"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        NSDictionary *err = [self parseErrorInfo:error];
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(NO, err);
        }
    };
    
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [self requestURLString:urlString];
    }
    AFHTTPSessionManager *manager = [self pushRequestSessionManager];
    
    if ([urlString hasPrefix:@"https:"] || [manager.baseURL.absoluteString hasPrefix:@"https:"]) {
        //设置 https 请求证书
        [self setCertificatesWithManager:manager];
    }
    
    switch (method) {
        case SHRequestMethodGET:
            [manager GET:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPOST:
            [manager POST:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPUT:
            [manager PUT:urlString parameters:parametes success:success failure:failure];
            break;
            
        case SHRequestMethodDELETE:
            [manager DELETE:urlString parameters:parametes success:success failure:failure];
            break;
            
        default:
            break;
    }
}

- (AFHTTPSessionManager *)pushRequestSessionManager {
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    // https request must set baseURL
    NSURL *url = [NSURL URLWithString:ServerBaseUrl];
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithBaseURL:url];
    
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token ? self.userAccount.access_token : @""];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];

    return manager;
}

- (NSString *)requestURLString:(NSString *)urlString {
    return [ServerBaseUrl stringByAppendingString:urlString];
}

- (BOOL)setCertificatesWithManager:(AFURLSessionManager *)manager
{
    if([ServerUrl sharedServerUrl].useSSL) { //使用自制证书
        // /先导入证书
        NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"icatchtek" ofType:@"cer"];//证书的路径
        NSData *certData = [NSData dataWithContentsOfFile:cerPath];
        
        // AFSSLPinningModeCertificate 使用证书验证模式
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
        
        // allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
        // 如果是需要验证自建证书，需要设置为YES
        securityPolicy.allowInvalidCertificates = YES;
        
        //validatesDomainName 是否需要验证域名，默认为YES；
        //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
        //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
        //如置为NO，建议自己添加对应域名的校验逻辑。
        securityPolicy.validatesDomainName = NO;
        NSSet <NSData *>* pinnedCertificates = [NSSet setWithObject:certData];
        
        //securityPolicy.pinnedCertificates = @[certData];
        securityPolicy.pinnedCertificates = pinnedCertificates;
        [manager setSecurityPolicy:securityPolicy];
    }
    
    return YES;
}

#pragma mark - Error Handle
- (NSDictionary *)parseErrorInfo:(NSError * _Nonnull)error {
    NSData *data = error.userInfo[@"com.alamofire.serialization.response.error.data"];
    
    NSDictionary *dict = @{
                           @"error_description": @"Unknown Error",
                           };
    
    if (data != nil) {
        id temp = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if (error) {
            dict = temp;
        }
    }
    
    return dict;
}

@end
