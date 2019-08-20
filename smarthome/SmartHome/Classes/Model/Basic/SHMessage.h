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
@property (nonatomic, copy) NSNumber *msgID;
@property (nonatomic, copy) NSNumber *msgType;
@property (nonatomic, copy) NSNumber *timeInSecs;

@property (nonatomic, copy, readonly) NSString *msgTypeString;

- (instancetype)initMessageWithDict:(NSDictionary *)dict;
+ (instancetype)messageWithDict:(NSDictionary *)dict;

@end
