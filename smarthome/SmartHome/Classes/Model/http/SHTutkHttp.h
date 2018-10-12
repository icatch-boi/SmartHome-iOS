//
//  SHTutkHttp.h
//  SmartHome
//
//  Created by yh.zhang on 2017/10/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHTutkHttp : NSObject

+ (void)registerDevice:(SHCamera *)camera;
+ (BOOL)unregisterDevice:(NSString *)uid;

@end
