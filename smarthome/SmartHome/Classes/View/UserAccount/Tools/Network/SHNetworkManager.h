//
//  SHNetworkManager.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SHAccountManagementKit/SHAccountManagementKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
typedef enum : NSUInteger {
    SHRequestMethodGET,
    SHRequestMethodPOST,
    SHRequestMethodPUT,
    SHRequestMethodDELETE,
} SHRequestMethod;

static NSTimeInterval TIME_OUT_INTERVAL = 15.0;

//static NSString * const ServerBaseUrl = @"http://52.79.113.238:3006/";
static NSString * const kServerCustomerid = @"5aa0d55246c14813a2313c17";

#define Use_OurServer 1
#define Use_LocalServer 1

#if Use_OurServer

#if Use_LocalServer
static NSString * const ServerBaseUrl = @"http://52.83.116.127:3006/"; //@"http://172.28.28.17:80/";
#else
static NSString * const ServerBaseUrl = @"http://www.smarthome.icatchtek.com/";
#endif

#else
static NSString * const ServerBaseUrl = @"https://www.smarthome.icatchtek.com/";
#endif

@class SHUserAccount;
@interface SHNetworkManager : NSObject

@property (nonatomic, assign, readonly) BOOL userLogin;
@property (nonatomic, strong) CameraOperate *cameraOperate;
@property (nonatomic, strong) SHUserAccount *userAccount;

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

@end

NS_ASSUME_NONNULL_END
