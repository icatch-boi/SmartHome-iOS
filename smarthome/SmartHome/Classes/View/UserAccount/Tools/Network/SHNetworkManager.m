//
//  SHNetworkManager.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHNetworkManager.h"
#import "SHUserAccount.h"
#import "SHNetworkManager+SHPush.h"
#import "ZJRequestError.h"
#import <AFNetworking/AFNetworking.h>

@interface SHNetworkManager ()

@property (nonatomic, strong) TokenOperate *tokenOperate;
@property (nonatomic, strong) AccountOperate *accountOperate;

@end

@implementation SHNetworkManager
-(void)showErr:(NSNotification *)sender {
    if(sender) {
        Error *err = sender.object;

        SHLogInfo(SHLogTagAPP, @"sender : %@", err/*.error_description*/);
    } else {
        SHLogError(SHLogTagAPP, @"nil object !!!");
    }
}
+ (instancetype)sharedNetworkManager {
    static SHNetworkManager *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:instance selector:@selector(showErr:) name:reloginNotifyName object:nil];
        [ServerUrl sharedServerUrl].BaseUrl = kServerBaseURL;
    });
    
    return instance;
}

- (void)getVerifyCodeWithEmail:(NSString *)email completion:(RequestCompletionBlock)completion
{
    [self.tokenOperate checkMailValid:email customerid:kServerCustomerID success:^{
        if (completion) {
            completion(YES, nil);
        }
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"getVerifyCodeWithEmail failed, error: %@", error.error_description);

        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)resetPwdGetVerifyCodeWithEmail:(NSString * _Nonnull)email
                            completion:(RequestCompletionBlock)completion
{
    [self.accountOperate restUserPwdBegWithMail:email customerid:kServerCustomerID success:^{
        if (completion) {
            completion(YES, nil);
        }
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"resetPwdGetVerifyCodeWithEmail failed, error: %@", error.error_description);

        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)resetPwdWithEmail:(NSString * _Nonnull)email
              andPassword:(NSString * _Nonnull)password
                  andCode:(NSString * _Nonnull)code
               completion:(RequestCompletionBlock)completion
{
    [self.accountOperate resetUserPwdWithEmail:email andNewPwd:password andCheckCode:code customerid:kServerCustomerID success:^(Account * _Nonnull account) {
        if (completion) {
            completion(YES, account);
        }
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"resetPwdWithEmail failed, error: %@", error.error_description);

        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(RequestCompletionBlock)completion {
    [self.accountOperate changeAccountPasswrodWithToken:[self createToken] andOldPassword:oldPassword andNewPasswrod:newPassword customerid:kServerCustomerID success:^(Account * _Nonnull account) {
        
        NSString *accountId = [[NSUserDefaults standardUserDefaults] objectForKey:kUserAccounts];
        accountId = accountId ? accountId : account.email;
        [self loadAccessTokenByEmail:accountId password:newPassword completion:^(BOOL isSuccess, id  _Nonnull result) {
            if (completion) {
                completion(YES, account);
            }
        }];
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"changePasswordWithOldPassword failed, error: %@", error.error_description);

        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)loadAccessTokenByEmail:(NSString *)email password:(NSString *)password completion:(RequestCompletionBlock)completion {
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
    SHLogInfo(SHLogTagAPP, @"This is device Token: %@", deviceToken);
    deviceToken = deviceToken ? deviceToken : @"";
    
    [self.tokenOperate getTokenByEmail:email andPassword:password andDeviceIdentification:deviceToken /*@"smarthome-v1"*/ success:^(Token * _Nonnull token) {
        SHLogInfo(SHLogTagAPP, @"access token: %@", token.access_token);
        
        self.userAccount.access_token = token.access_token;
        self.userAccount.expires_in = token.expires_in;
        self.userAccount.refresh_token = token.refresh_token;
        _cameraOperate = nil;
        
        [self.accountOperate signInWithToken:token success:^(Account * _Nonnull account) {
            self.userAccount.screen_name = account.name;
            self.userAccount.avatar_large = account.portrait;
            self.userAccount.id = account.id;
            
            [self.userAccount saveUserAccount];
            
            SHLogInfo(SHLogTagAPP, @"userAccount: %@", self.userAccount);
            [[NSUserDefaults standardUserDefaults] setObject:email forKey:kUserAccounts];
            if (completion) {
                completion(YES, account);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"loadAccessTokenByEmail failed, error: %@", error.error_description);

//            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAccounts];
            if (completion) {
                completion(NO, error);
            }
        }];
        
        [self registerClient:deviceToken finished:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"register client success: %d", isSuccess);
        }];
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"loadAccessTokenByEmail failed, error: %@", error.error_description);

//        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAccounts];
        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)logonWithUserName:(NSString *)userName email:(NSString *)email password:(NSString *)password checkCode:(NSString *)checkCode completion:(RequestCompletionBlock)completion {
    [self.accountOperate signUpWithUserName:[self repairNickName:userName] andEmail:email andPassword:password andCheckCode:checkCode customerid:kServerCustomerID success:^(Account * _Nonnull account) {
        
        if (completion) {
            completion(YES, account);
        }
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagAPP, @"logon failed error: %@", error.error_description);
        SHLogError(SHLogTagAPP, @"error code: %ld", (long)error.error_code);
        
        if (completion) {
            completion(NO, error);
        }
    }];
}

- (NSString *)repairNickName:(NSString *)nickName {
    if ([nickName containsString:@"@"]) {
        NSRange range = [nickName rangeOfString:@"@"];
        nickName = [nickName substringToIndex:range.location];
    }
    
    return nickName;
}

- (void)logoutWithCompation:(RequestCompletionBlock)completion {
//    self.userAccount.access_token = nil;
//    self.userAccount.refresh_token = nil;
    
#if 0
    [self.tokenOperate deleteToken:[self createToken] andDeviceIdentification:@"smarthome-v1" success:^{
        [self.userAccount deleteUserAccount];

        _userAccount = nil;
        [[SHCameraManager sharedCameraManger] unmappingAllCamera];

        if (completion) {
            completion(YES, nil);
        }
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"deleteToken failed, error: %@" , error.error_description);
        if (completion) {
            completion(NO, error);
        }
    }];
#else
    [self revokeTokenWithCompation:^(BOOL isSuccess, id  _Nullable result) {
        if (isSuccess) {
            [self.userAccount deleteUserAccount];
            
            _userAccount = nil;
            [[SHCameraManager sharedCameraManger] unmappingAllCamera];
            
            if (completion) {
                completion(YES, nil);
            }
        } else {
            ZJRequestError *error = result;
            SHLogError(SHLogTagSDK, @"deleteToken failed, error: %@" , error.error_description);
            if (completion) {
                completion(NO, error);
            }
        }
    }];
#endif
}

- (void)refreshToken:(RequestCompletionBlock)completion {
    if (self.userAccount.access_token == nil || self.userAccount.refresh_token == nil) {
        if (completion) {
            Error *error = [[Error alloc] initWithErrorCode:-1024 andName:@"refreshToken error" andError:@"refreshToken parameter invalid" andErrorDescription:@"access_token or refresh_token is nil."];
            completion(NO, error);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];

        return;
    }
    
    Token *token = [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token,
                                                 @"refresh_token" : self.userAccount.refresh_token,
                                                 }];

    [self.tokenOperate refreshToken:token andDeviceIdentification:@"smarthome-v1" success:^(Token * _Nonnull newToken) {
        self.userAccount.access_token = newToken.access_token;
        self.userAccount.expires_in = newToken.expires_in;
        self.userAccount.refresh_token = newToken.refresh_token;
        _cameraOperate = nil;
        
        if (completion) {
            completion(YES, newToken);
        }

//        Token *token = [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token,
//                                                     @"refresh_token" : self.userAccount.refresh_token,
//                                                     }];
        Token *token = [self createToken];
        
        [self.accountOperate acquireAccountInfoWithToken:token andUserId:self.userAccount.id success:^(Account * _Nonnull account) {
            self.userAccount.screen_name = account.name;
            self.userAccount.avatar_large = account.portrait;
            self.userAccount.id = account.id;
            
            [self.userAccount saveUserAccount];
            
            SHLogInfo(SHLogTagAPP, @"userAccount: %@", self.userAccount);
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagAPP, @"acquireAccountInfoWithToken failed, error: %@", error.error_description);
        }];
        
        NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
        SHLogInfo(SHLogTagAPP, @"This is device Token: %@", deviceToken);
        [self registerClient:deviceToken finished:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"register client success: %d", isSuccess);
        }];
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"refreshToken failed, error: %@", error.error_description);

//        [self logoutWithCompation:nil];
        [self.userAccount deleteUserAccount];
        [[SHCameraManager sharedCameraManger] unmappingAllCamera];

        _userAccount = nil;
        
        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)acquireAccountInfoWithUserID:(NSString *)userID completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate acquireAccountInfoWithToken:[self createToken] andUserId:userID success:^(Account * _Nonnull account) {
            
            if (completion) {
                completion(YES, account);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"acquireAccountInfoWithUserID failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate acquireAccountInfoWithToken:[self createToken] andUserId:userID success:^(Account * _Nonnull account) {
                    if (completion) {
                        completion(YES, account);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"acquireAccountInfoWithUserID failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)setUserAvatorWithData:(NSData *)avatorData completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate setAvatorWithToken:[self createToken] andAvatorData:avatorData success:^(NSString * _Nonnull url) {
            if (completion) {
                completion(YES, url);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"setUserAvatorWithData failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate setAvatorWithToken:[self createToken] andAvatorData:avatorData success:^(NSString * _Nonnull url) {
                    if (completion) {
                        completion(YES, url);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"setUserAvatorWithData failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)getUserAvator:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate getAvatorWithToken:[self createToken] success:^(NSString * _Nonnull url) {
            if (completion) {
                completion(YES, url);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getUserAvator failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate getAvatorWithToken:[self createToken] success:^(NSString * _Nonnull url) {
                    if (completion) {
                        completion(YES, url);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getUserAvator failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)getMessages:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate getMessagesWithToken:[self createToken] success:^(NSArray * _Nonnull messages) {
            if (completion) {
                completion(YES, messages);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getMessages failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate getMessagesWithToken:[self createToken] success:^(NSArray * _Nonnull messages) {
                    if (completion) {
                        completion(YES, messages);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getMessages failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)getMessageWithMessageId:(NSString *)msgId completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate getMessageWithToken:[self createToken] andMessageId:msgId success:^(Message * _Nonnull message) {
            if (completion) {
                completion(YES, message);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"getMessageWithMessageId failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate getMessageWithToken:[self createToken] andMessageId:msgId success:^(Message * _Nonnull message) {
                    if (completion) {
                        completion(YES, message);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"getMessageWithMessageId failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)clearMessageWithMessageIds:(NSArray *)msgIds completion:(RequestCompletionBlock)completion {
    if (self.userAccount.access_tokenHasEffective) {
        [self.accountOperate clearMessageWithToken:[self createToken] andMessageIds:msgIds success:^{
            if (completion) {
                completion(YES, nil);
            }
        } failure:^(Error * _Nonnull error) {
            SHLogError(SHLogTagSDK, @"clearMessageWithMessageIds failed, error: %@", error.error_description);

            if (completion) {
                completion(NO, error);
            }
        }];
    } else {
        [self refreshToken:^(BOOL isSuccess, id result) {
            if (isSuccess) {
                [self.accountOperate clearMessageWithToken:[self createToken] andMessageIds:msgIds success:^{
                    if (completion) {
                        completion(YES, nil);
                    }
                } failure:^(Error * _Nonnull error) {
                    SHLogError(SHLogTagSDK, @"clearMessageWithMessageIds failed, error: %@", error.error_description);

                    if (completion) {
                        completion(NO, error);
                    }
                }];
            }
        }];
    }
}

- (void)revokeTokenWithCompation:(RequestCompletionBlock)completion {
    NSString *urlString = [self requestURLString:REVOKE_TOKEN_PATH];
    
    Token *temp = [self createToken];
    NSDictionary *dict = @{
                           @"token_type_hint": temp.refresh_token,
                           @"token": temp.access_token
                           };

    [self requestWithMethod:SHRequestMethodPOST manager:nil urlString:urlString parameters:dict finished:completion];
}

#pragma mark -
- (Token *)createToken {
    if (self.userAccount.access_token == nil || self.userAccount.refresh_token == nil) {
        [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
    }
    
    return [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token ? self.userAccount.access_token : @"",
                                         @"refresh_token" : self.userAccount.refresh_token ? self.userAccount.refresh_token : @"",
                                         }];
}

/**************************************************/
- (SHUserAccount *)userAccount {
    if (_userAccount == nil) {
        _userAccount = [[SHUserAccount alloc] init];
    }
    
    return _userAccount;
}

- (TokenOperate *)tokenOperate {
    if (_tokenOperate == nil) {
        _tokenOperate = [[TokenOperate alloc] init];
    }
    
    return _tokenOperate;
}

- (AccountOperate *)accountOperate {
    if (_accountOperate == nil) {
        _accountOperate = [[AccountOperate alloc] init];
    }
    
    return _accountOperate;
}

- (BOOL)userLogin {
    return self.userAccount.access_token != nil;
}

- (CameraOperate *)cameraOperate {
    if (_cameraOperate == nil) {
        _cameraOperate = [[CameraOperate alloc] init];
    }
    
    return _cameraOperate;
}

#pragma mark - Network Handle
- (void)dataTaskWithRequest:(NSURLRequest *)request completion:(RequestCompletionBlock)completion {
    if (request == nil) {
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description": @"This parameter must not be `nil`.",
                                   };
            completion(NO, [self createErrorWithCode:ZJRequestErrorCodeInvalidParameters userInfo:dict]);
        }
        
        return;
    }
    
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    [[manager dataTaskWithRequest:request uploadProgress:nil downloadProgress:nil completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error != nil) {
            ZJRequestError *err = [ZJRequestError requestErrorWithNSError:error];
            SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
            
            if (completion) {
                completion(NO, err);
            }
            
            return;
        }
        
        NSHTTPURLResponse *respose = (NSHTTPURLResponse *)response;
        
        if (respose.statusCode == 200 || respose.statusCode == 304) {
            if (completion) {
                completion(YES, responseObject);
            }
        } else {
            if (respose.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
                
                [[NSNotificationCenter defaultCenter] postNotificationName:reloginNotifyName object:nil];
            }
            
            ZJRequestError *err = [ZJRequestError requestErrorWithDict:@{@"error_description": @"Server internal error."}];
            SHLogError(SHLogTagAPP, @"服务器内部错误!");
            
            if (completion) {
                completion(NO, err);
            }
        }
    }] resume];
}

#pragma mark - Request method
- (void)requestWithMethod:(SHRequestMethod)method manager:(AFHTTPSessionManager * _Nullable)manager urlString:(NSString *)urlString parameters:(id _Nullable)parameters finished:(RequestCompletionBlock)finished {
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
        
        ZJRequestError *err = [ZJRequestError requestErrorWithNSError:error];
        SHLogError(SHLogTagAPP, @"网络请求错误: %@", error);
        
        if (finished) {
            finished(NO, err);
        }
    };
    
    if (![urlString hasPrefix:@"http://"] && ![urlString hasPrefix:@"https://"]) {
        urlString = [self requestURLString:urlString];
    }
    
    if ([urlString hasPrefix:@"https:"] || [manager.baseURL.absoluteString hasPrefix:@"https:"]) {
        //设置 https 请求证书
        [self setCertificatesWithManager:manager];
    }
    
    if (manager == nil) {
        manager = [self defaultRequestSessionManager];
    }
    
    switch (method) {
        case SHRequestMethodGET:
            [manager GET:urlString parameters:parameters progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPOST:
            [manager POST:urlString parameters:parameters progress:nil success:success failure:failure];
            break;
            
        case SHRequestMethodPUT:
            [manager PUT:urlString parameters:parameters success:success failure:failure];
            break;
            
        case SHRequestMethodDELETE:
            [manager DELETE:urlString parameters:parameters success:success failure:failure];
            break;
            
        default:
            break;
    }
}

- (NSString *)requestURLString:(NSString *)urlString {
    return [kServerBaseURL stringByAppendingString:urlString];
}

- (AFHTTPSessionManager *)defaultRequestSessionManager {
    NSString *token = [@"Bearer " stringByAppendingString:self.userAccount.access_token ? self.userAccount.access_token : @""];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:token forHTTPHeaderField:@"Authorization"];
    
    return manager;
}

#pragma mark - Error Handle
- (ZJRequestError *)createErrorWithCode:(NSInteger)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey, id> *)dict {
    return [ZJRequestError requestErrorWithDict:dict];
}

#pragma mark - Certificate Handle
- (BOOL)setCertificatesWithManager:(AFURLSessionManager *)manager {
    if ([ServerUrl sharedServerUrl].useSSL) { //使用自制证书
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

@end
