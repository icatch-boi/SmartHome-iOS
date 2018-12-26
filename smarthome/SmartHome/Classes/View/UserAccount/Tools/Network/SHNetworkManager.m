//
//  SHNetworkManager.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHNetworkManager.h"
#import "SHUserAccount.h"
//#import <SHAccountManagementKit/TokenOperate.h>
#import "SHNetworkManager+SHPush.h"

@interface SHNetworkManager ()

@property (nonatomic, strong) TokenOperate *tokenOperate;
@property (nonatomic, strong) AccountOperate *accountOperate;

@end

@implementation SHNetworkManager
-(void)showErr:(NSNotification *)sender {
    if(sender) {
        Error *err = sender.object;

        SHLogInfo(SHLogTagAPP, @"sender : %@", err.error_description);
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
        [ServerUrl sharedServerUrl].BaseUrl = ServerBaseUrl;
    });
    
    return instance;
}

- (void)getVerifyCodeWithEmail:(NSString *)email completion:(RequestCompletionBlock)completion
{
    [self.tokenOperate checkMailValid:email success:^{
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
    [self.accountOperate restUserPwdBegWithMail:email success:^{
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
    [self.accountOperate resetUserPwdWithEmail:email andNewPwd:password andCheckCode:code success:^(Account * _Nonnull account) {
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
    [self.accountOperate changeAccountPasswrodWithToken:[self createToken] andOldPassword:oldPassword andNewPasswrod:newPassword success:^(Account * _Nonnull account) {
        
        [self loadAccessTokenByEmail:account.email password:newPassword completion:^(BOOL isSuccess, id  _Nonnull result) {
            if (completion) {
                completion(isSuccess, result);
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

            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAccounts];
            if (completion) {
                completion(NO, error);
            }
        }];
        
        [self registerClient:deviceToken finished:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"register client success: %d", isSuccess);
        }];
    } failure:^(Error * _Nonnull error) {
        SHLogError(SHLogTagSDK, @"loadAccessTokenByEmail failed, error: %@", error.error_description);

        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kUserAccounts];
        if (completion) {
            completion(NO, error);
        }
    }];
}

- (void)logonWithUserName:(NSString *)userName email:(NSString *)email password:(NSString *)password checkCode:(NSString *)checkCode completion:(RequestCompletionBlock)completion {
    [self.accountOperate signUpWithUserName:[self repairNickName:userName] andEmail:email andPassword:password andCheckCode:checkCode success:^(Account * _Nonnull account) {
        
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
}

- (void)refreshToken:(RequestCompletionBlock)completion {
    if (self.userAccount.access_token == nil || self.userAccount.refresh_token == nil) {
        if (completion) {
            Error *error = [[Error alloc] initWithErrorCode:-1024 andName:@"refreshToken error" andError:@"refreshToken parameter invalid" andErrorDescription:@"access_token or refresh_token is nil."];
            completion(NO, error);
        }
        
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

        Token *token = [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token,
                                                     @"refresh_token" : self.userAccount.refresh_token,
                                                     }];
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

#pragma mark -
- (Token *)createToken {
    return [[Token alloc] initWithData:@{@"access_token" : self.userAccount.access_token,
                                         @"refresh_token" : self.userAccount.refresh_token,
                                         }];
}

/**************************************************/
- (SHUserAccount *)userAccount {
    if (_userAccount == nil) {
        _userAccount = [[SHUserAccount alloc] init];
        
//        if (_userAccount.access_token && _userAccount.refresh_token) {
//            [self refreshToken:^(BOOL isSuccess, id  _Nonnull result) {
//                NSLog(@"refreshToken is success: %d", isSuccess);
//
//                if (!isSuccess) {
//                    Error *error = result;
//                    NSLog(@"refreshToken is failed: %@", error.error_description);
//                }
//            }];
//        }
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

@end
