// SHENetworkManager.m

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
 
 // Created by zj on 2019/9/10 11:40 AM.
    

#import "SHENetworkManager.h"
#import <AFNetworking/AFNetworking.h>
#import "SHNetworkManager.h"
#import "SHUserAccount.h"

@interface SHENetworkManager ()

@property (nonatomic, strong) AFHTTPSessionManager *defaultSessionManager;
@property (nonatomic, strong) AFHTTPSessionManager *tokenSessionManager;

@end

@implementation SHENetworkManager

#pragma mark - Init
+ (instancetype)sharedManager {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.defaultSessionManager = [self createSessionManager];
        
        self.tokenSessionManager = [self createSessionManager];
        self.tokenSessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        self.tokenSessionManager.completionQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        [self configAuthorization];
    }
    return self;
}

- (AFHTTPSessionManager *)createSessionManager {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/plain", nil];
    
    return manager;
}

- (void)configAuthorization {
    NSLog(@"mutableHTTPRequestHeaders: %@", self.tokenSessionManager.requestSerializer.HTTPRequestHeaders);

    if (self.access_token != nil) {
        NSString *token = [@"Bearer " stringByAppendingString:self.access_token];
        
        [self.tokenSessionManager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    }
}

- (NSString *)access_token {
    return [SHNetworkManager sharedNetworkManager].userAccount.access_token;
}

#pragma mark - Request method
- (void)tokenRequestWithMethod:(SHERequestMethod)method urlString:(NSString *)urlString parametes:(nullable id)parametes completion:(SHERequestCompletionBlock _Nullable)completion {
    
    if (self.access_token == nil) {
        SHLogError(SHLogTagAPP, @"access_token is nil, need login.");
        [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        
        if (completion) {
            completion(NO, nil);
        }
        
        return;
    }
    
    BOOL access_tokenExpire = ![SHNetworkManager sharedNetworkManager].userAccount.access_tokenHasEffective;
    if (access_tokenExpire) {
        // First refresh token
        WEAK_SELF(self);
        [[SHNetworkManager sharedNetworkManager] refreshToken:^(BOOL isSuccess, id  _Nullable result) {
            if (isSuccess) {
                [weakself configAuthorization];
                
                [weakself requestWithMethod:method manager:weakself.tokenSessionManager urlString:urlString parametes:parametes completion:completion];
            } else {
                if (completion) {
                    completion(isSuccess, result);
                }
            }
        }];
    } else {
        NSLog(@"mutableHTTPRequestHeaders: %@", self.tokenSessionManager.requestSerializer.HTTPRequestHeaders);
        
        [self requestWithMethod:method manager:self.tokenSessionManager urlString:urlString parametes:parametes completion:completion];
    }
}

- (void)requestWithMethod:(SHERequestMethod)method urlString:(NSString *)urlString parametes:(nullable id)parametes completion:(SHERequestCompletionBlock _Nullable)completion {
    NSLog(@"mutableHTTPRequestHeaders: %@", self.defaultSessionManager.requestSerializer.HTTPRequestHeaders);
    
    [self requestWithMethod:method manager:self.defaultSessionManager urlString:urlString parametes:parametes completion:completion];
}

- (void)requestWithMethod:(SHERequestMethod)method manager:(AFHTTPSessionManager * _Nullable)manager urlString:(NSString *)urlString parametes:(nullable id)parametes completion:(SHERequestCompletionBlock _Nullable)completion {
    id success = ^(NSURLSessionDataTask *_Nonnull task, id _Nullable responseObject) {
        if (completion) {
            completion(YES, responseObject);
        }
    };
    
    id failure = ^(NSURLSessionDataTask * _Nonnull task, NSError * _Nonnull error) {
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)task.response;
        
        if (respose.statusCode == 401) {
            NSLog(@"Token invalid.");
            
            [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
        }
        
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (completion) {
            completion(NO, error);
        }
    };
    
    if (manager == nil) {
        manager = self.defaultSessionManager;
    }
    
    switch (method) {
        case SHERequestMethodGET:
            [manager GET:urlString parameters:parametes progress:nil success:success failure:failure];
            break;
            
        case SHERequestMethodPOST:
            [manager POST:urlString parameters:parametes progress:nil success:success failure:failure];
            
        case SHERequestMethodPUT:
            [manager PUT:urlString parameters:parametes success:success failure:failure];
            
        case SHERequestMethodDELETE:
            [manager DELETE:urlString parameters:parametes success:success failure:failure];
            
        default:
            break;
    }
}

@end
