//
//  Account.h
//  SHAccountManagementKit
//
//  Created by 江果 on 01/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Account : NSObject

@property(nonatomic, readonly) NSString * _Nonnull name;
@property(nonatomic, readonly) NSString * _Nonnull email;
//@property(nonatomic, readonly) NSString * _Nonnull password; //v2.4 remove
@property(nonatomic, readonly) NSString * _Nonnull id;
@property(nonatomic, readonly) BOOL email_verified;
@property(nonatomic, readonly) NSString * _Nonnull portrait;
@property(nonatomic, readonly) NSString * setting; //v2.4 add

-(instancetype _Nonnull )initWithData:(NSDictionary *_Nonnull)dict;

@end
