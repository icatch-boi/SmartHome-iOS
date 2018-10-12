//
//  Token.h
//  SHAccountManagementKit
//
//  Created by 江果 on 01/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * reloginNotifyName = @"invalid_token";

@interface Token : NSObject

@property(nonatomic, readonly) NSString * _Nonnull access_token;
@property(nonatomic, readonly) NSString * _Nonnull access_token_type;
@property(nonatomic, readonly) long expires_in;
@property(nonatomic, readonly) NSString * _Nonnull refresh_token;


-(instancetype _Nonnull )initWithData:(NSDictionary * _Nonnull)dict;

-(NSString *_Nonnull)bearerToken;
-(void)debug;

@end
