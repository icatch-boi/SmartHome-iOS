//
//  AccountOperate.h
//  SHAccountManagementKit
//
//  Created by 江果 on 01/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Account.h"
#import "Token.h"
#import "Error.h"
#import "Message.h"
#import "BasicFriendInfo.h"

@interface AccountOperate : NSObject


-(void)signUpWithUserName:(NSString *_Nonnull)userName
                 andEmail:(NSString *_Nonnull)email
              andPassword:(NSString *_Nonnull)password
             andCheckCode:(NSString *_Nonnull)code
               customerid:(NSString *_Nonnull)customerid
                  success:(nullable void (^)(Account* _Nonnull account))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)signInWithToken:(Token * _Nonnull)token
               success:(nullable void (^)(Account* _Nonnull account))success
               failure:(nullable void (^)(Error* _Nonnull error))failure;


-(void)restUserPwdBegWithMail:(NSString *_Nonnull)email
                   customerid:(NSString *_Nonnull)customerid
              success:(nullable void (^)(void))success
              failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)resetUserPwdWithEmail:(NSString *_Nonnull)email
          andNewPwd:(NSString * _Nonnull)newPwd
       andCheckCode:(NSString * _Nonnull)code
                  customerid:(NSString *_Nonnull)customerid
            success:(nullable void (^)(Account* _Nonnull account))success
            failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)acquireAccountInfoWithToken:(Token * _Nonnull)token
                         andUserId:(NSString *_Nonnull)userId
                           success:(nullable void (^)(Account* _Nonnull account))success
                           failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)acquireAccountInfoWithToken:(Token * )token
                           success:( void (^)(Account* _Nonnull account))success
                           failure:( void (^)(Error* _Nonnull error))failure;

//用户信息更改
//add v2.4
-(void)changeAccountPasswrodWithToken:(Token * _Nonnull)Token
                       andOldPassword:(NSString * _Nonnull)oldPwd
                       andNewPasswrod:(NSString * _Nonnull)newPwd
                           customerid:(NSString * _Nonnull)customerid
                              success:(nullable void (^)(Account* _Nonnull account))success
                              failure:(nullable void (^)(Error* _Nonnull error))failure;
//add v2.4
-(void)changeAccountInfoWithToken:(Token * _Nonnull)Token
                           andNewName:(NSString * _Nullable)name
                           andNewInfo:(NSString * _Nullable)info
                       customerid:(NSString * _Nonnull)customerid
                              success:(nullable void (^)(Account* _Nonnull account))success
                              failure:(nullable void (^)(Error* _Nonnull error))failure;


-(void)changeAccountPasswrodWithToken:(Token * _Nonnull)Token
                           andNewName:(NSString *_Nonnull)name
                       andOldPassword:(NSString *_Nonnull)oldPwd
                       andNewPasswrod:(NSString *_Nonnull)newPwd
                           andNewInfo:(NSString *_Nonnull)info
                           customerid:(NSString * _Nonnull)customerid
                              success:(nullable void (^)(Account* _Nonnull account))success
                              failure:(nullable void (^)(Error* _Nonnull error))failure;


-(void)setAvatorWithToken:(Token *_Nonnull)token
            andAvatorData:(NSData *_Nonnull)avatorData
                  success:(nullable void (^)(NSString* _Nonnull url))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)getAvatorWithToken:(Token *_Nonnull)token
                  success:(nullable void (^)(NSString* _Nonnull url))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;




-(void)getMessagesWithToken:(Token *_Nonnull)token
                    success:(nullable void (^)(NSArray* _Nonnull messages))success
                    failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)getMessageWithToken:(Token *_Nonnull)token
              andMessageId:(NSString *_Nonnull)msgId
                   success:(nullable void (^)(Message* _Nonnull message))success
                   failure:(nullable void (^)(Error* _Nonnull error))failure;

//add v2.4
-(void)getMessagesWithToken:(Token * _Nonnull)token
           andMessageStatus:(int)msgStatus
                    success:(nullable void (^)(NSArray <Message*>* _Nonnull message))success
                    failure:(nullable void (^)(Error* _Nonnull error))failure;

//add v2.4
-(void)fixMessageStatusWithToken:(Token * _Nonnull)token
                         andMsgId:(NSString * _Nonnull)msgId
                     andMsgStatus:(NSInteger)msgStatus
                          success:(nullable void (^)(void))success
                          failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)clearMessageWithToken:(Token *_Nonnull)token
               andMessageIds:(NSArray *_Nonnull)msgIds
                     success:(nullable void (^)(void))success
                     failure:(nullable void (^)(Error* _Nonnull error))failure;

//add v2.4 friend API
-(void)addFriendWithToken:(Token * _Nonnull)token
             withFriendId:(NSString * _Nonnull)friendId
           withFriendName:(NSString * _Nonnull)name
                  success:(nullable void (^)(BasicFriendInfo* _Nonnull friendInfo))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)fixFriendWithToken:(Token * _Nonnull)token
             withFrinedId:(NSString * _Nonnull)friendId
           withFriendName:(NSString * _Nonnull)frinedName
                  success:(nullable void (^)(BasicFriendInfo* _Nonnull friendInfo))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)getFriendWithToken:(Token * _Nonnull)token byFriendId:(NSString * _Nonnull)friendId
                  success:(nullable void (^)(BasicFriendInfo* _Nonnull friendInfo))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)getFriendWithToken:(Token * _Nonnull)token friendCount:(int) count
                  success:(nullable void (^)(NSArray <BasicFriendInfo*>* _Nonnull friendInfo))success
                  failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)deleteFriendWithToken:(Token * _Nonnull)token
                  byFriendId:(NSString * _Nonnull)friendId
                     success:(nullable void (^)(void))success
                     failure:(nullable void (^)(Error* _Nonnull error))failure;

@end
