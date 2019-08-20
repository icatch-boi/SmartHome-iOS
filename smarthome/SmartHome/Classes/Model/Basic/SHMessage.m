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

- (NSString *)msgTypeString {
    return [self translateMessageType:_msgType.unsignedIntegerValue];
}

- (NSString *)translateMessageType:(int)type {
    NSString *str = nil;
    
    switch (type) {
        case PushMessageTypePir:
            str = NSLocalizedString(@"kMonitorTypePir", nil);
            break;
        case PushMessageTypeRing:
            str = NSLocalizedString(@"kMonitorTypeRing", nil);
            break;
            
        case PushMessageTypeLowPower:
            str = @"LowPower";
            break;
            
        case PushMessageTypeSDCardFull:
            str = @"SDCardFull";
            break;
            
        case PushMessageTypeSDCardError:
            str = @"SDCardError";
            break;
            
        case PushMessageTypeFDHit:
            str = @"FD Hit";
            break;
            
        case PushMessageTypeFDMiss:
            str = @"FD Miss";
            break;
            
        case PushMessageTypePushTest:
            str = @"PushTest";
            break;
            
        case PushMessageTypeTamperAlarm:
            str = @"Demolish";
            break;
            
        default:
            str = @"unknown";
            break;
    }
    
    return str;
}

@end
