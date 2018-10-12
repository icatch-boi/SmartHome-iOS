//
//  SHMessage.h
//  SmartHome
//
//  Created by ZJ on 2017/6/6.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHMessage : NSObject

@property (nonatomic, copy) NSString *devID;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSString *msgParam;
@property (nonatomic, assign) NSInteger msgID;
@property (nonatomic, assign) NSInteger msgType;

- (instancetype)initMessageWithDict:(NSDictionary *)dict;
+ (instancetype)messageWithDict:(NSDictionary *)dict;

@end
