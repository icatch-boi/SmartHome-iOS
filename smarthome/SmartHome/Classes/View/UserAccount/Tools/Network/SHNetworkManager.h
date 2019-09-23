//
//  SHNetworkManager.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SHAccountManagementKit/SHAccountManagementKit.h>
#ifdef KUSE_S3_SERVICE
#import "SHENetworkManagerCommon.h"
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void(^RequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
typedef enum : NSUInteger {
    SHRequestMethodGET,
    SHRequestMethodPOST,
    SHRequestMethodPUT,
    SHRequestMethodDELETE,
} SHRequestMethod;

static NSTimeInterval TIME_OUT_INTERVAL = 15.0;
static NSString * const REVOKE_TOKEN_PATH = @"oauth2/revoke";
static NSString * const EXTENSIONS_INFO_PATH = @"v1/users/extensions";
static NSString * const USERS_PORTRAIT_PATH = @"v1/users/portrait";
static const NSUInteger PORTRAIT_MAX_SZIE = 60 * 1024;

@class SHUserAccount;
@class AFHTTPSessionManager;
@class ZJRequestError;
@interface SHNetworkManager : NSObject

@property (nonatomic, assign, readonly) BOOL userLogin;
@property (nonatomic, strong, readonly) CameraOperate *cameraOperate;
@property (nonatomic, strong, readonly) SHUserAccount *userAccount;

+ (instancetype)sharedNetworkManager;
- (void)getVerifyCodeWithEmail:(NSString *)email completion:(RequestCompletionBlock)completion;
- (void)resetPwdGetVerifyCodeWithEmail:(NSString * _Nonnull)email
                            completion:(RequestCompletionBlock)completion;

- (void)resetPwdWithEmail:(NSString * _Nonnull)email
                   andPassword:(NSString * _Nonnull)password
                  andCode:(NSString * _Nonnull)code
               completion:(RequestCompletionBlock)completion;

- (void)changePasswordWithOldPassword:(NSString *)oldPassword newPassword:(NSString *)newPassword completion:(RequestCompletionBlock)completion;

- (void)loadAccessTokenByEmail:(NSString *)email password:(NSString *)password completion:(RequestCompletionBlock)completion;
- (void)logonWithUserName:(NSString *)userName email:(NSString *)email password:(NSString *)password checkCode:(NSString *)checkCode completion:(RequestCompletionBlock)completion;
- (void)logoutWithCompation:(RequestCompletionBlock)completion;
- (void)refreshToken:(RequestCompletionBlock)completion;
- (void)acquireAccountInfoWithUserID:(NSString *)userID completion:(RequestCompletionBlock)completion;

- (void)setUserAvatorWithData:(NSData *)avatorData completion:(RequestCompletionBlock)completion;
- (void)getUserAvator:(RequestCompletionBlock)completion;

- (void)getMessages:(RequestCompletionBlock)completion;
- (void)getMessageWithMessageId:(NSString *)msgId completion:(RequestCompletionBlock)completion;
- (void)clearMessageWithMessageIds:(NSArray *)msgIds completion:(RequestCompletionBlock)completion;

- (void)dataTaskWithRequest:(NSURLRequest *)request completion:(RequestCompletionBlock)completion;
- (void)requestWithMethod:(SHRequestMethod)method manager:(AFHTTPSessionManager * _Nullable)manager urlString:(NSString *)urlString parameters:(id _Nullable)parameters finished:(RequestCompletionBlock)finished;

- (void)setUserExtensionsInfo:(NSDictionary *)info completion:(RequestCompletionBlock)completion;
- (void)getUserExtensionsInfoWithCompletion:(RequestCompletionBlock)completion;
- (void)deleteUserExtensionsInfoWithCompletion:(RequestCompletionBlock)completion;

- (void)downloadFileWithURLString:(NSString *)urlString finished:(RequestCompletionBlock)finished;

@end

NS_ASSUME_NONNULL_END
