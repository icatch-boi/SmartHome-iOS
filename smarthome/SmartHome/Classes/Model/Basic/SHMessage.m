//
//  SHMessage.m
//  SmartHome
//
//  Created by ZJ on 2017/6/6.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHMessage.h"

@implementation SHMessage

- (instancetype)initMessageWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
}

+ (instancetype)messageWithDict:(NSDictionary *)dict {
    return [[self alloc] initMessageWithDict:dict];
}

@end
