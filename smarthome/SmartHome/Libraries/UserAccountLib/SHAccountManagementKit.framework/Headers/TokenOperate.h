//
//  TokenOperate.h
//  SHAccountManagementKit
//
//  Created by 江果 on 01/02/2018.
//  Copyright © 2018 iCatchTek. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Token.h"
#import "Error.h"

@interface TokenOperate : NSObject
-(void)checkMailValid:(NSString *)email
           customerid:(NSString * _Nonnull)customerid
              success:(nullable void (^)(void))success
              failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)getTokenByEmail:(NSString *_Nonnull)email
           andPassword:(NSString *_Nonnull)password
andDeviceIdentification:(NSString *_Nonnull)devIdentification
               success:(nullable void (^)(Token* _Nonnull token))success
               failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)refreshToken:(Token *_Nonnull)token
   andDeviceIdentification:(NSString *_Nonnull)devIdentification
            success:(nullable void (^)(Token* _Nonnull newToken))success
            failure:(nullable void (^)(Error* _Nonnull error))failure;

-(void)deleteToken:(Token *_Nonnull)token
andDeviceIdentification:(NSString *_Nonnull)devIdentification
           success:(nullable void (^)(void))success
           failure:(nullable void (^)(Error* _Nonnull error))failure;

@end

