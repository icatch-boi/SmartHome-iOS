//
//  HttpRequest.h
//  SmartHome
//
//  Created by yh.zhang on 2017/10/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HttpRequest : NSObject
+ (BOOL) getSyncWithUrl:(NSString *)url;
+ (void) postSyncWithUrl:(NSString *)url :(NSString *)jsonData;
@end
