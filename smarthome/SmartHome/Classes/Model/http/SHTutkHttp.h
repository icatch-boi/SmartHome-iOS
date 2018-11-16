//
//  SHTutkHttp.h
//  SmartHome
//
//  Created by yh.zhang on 2017/10/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^PushRequestCompletionBlock)(BOOL isSuccess);
//#define USE_SYNC_REQUEST_PUSH

@interface SHTutkHttp : NSObject

+ (void)registerDevice:(SHCamera *)camera;
+ (BOOL)unregisterDevice:(NSString *)uid;

+ (void)unregisterDevice:(NSString *)uid completionHandler:(PushRequestCompletionBlock)completionHandler;

@end
