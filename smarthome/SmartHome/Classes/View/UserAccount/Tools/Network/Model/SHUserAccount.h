//
//  SHUserAccount.h
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHUserAccount : NSObject

@property (nonatomic, copy) NSString *access_token;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *screen_name;
@property (nonatomic, copy) NSString *avatar_large;
@property (nonatomic, strong) NSDate *expiresDate;
@property (nonatomic, assign) NSTimeInterval expires_in;
@property (nonatomic, copy) NSString *refresh_token;
@property (nonatomic, copy) NSDictionary *userExtensionsInfo;

- (void)saveUserAccount;
- (void)deleteUserAccount;
- (BOOL)access_tokenHasEffective;

@end
