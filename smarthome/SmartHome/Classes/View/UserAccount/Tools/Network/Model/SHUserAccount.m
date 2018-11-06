//
//  SHUserAccount.m
//  SHAccountsManagement
//
//  Created by ZJ on 2018/2/28.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHUserAccount.h"
#import <objc/runtime.h>

static NSString * const kSHUserAccount = @"kSHUserAccount";

@implementation SHUserAccount

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:kSHUserAccount];
        
        if (dict != nil) {
            [self setValuesForKeysWithDictionary:dict];
            
            if ([self.expiresDate compare:[NSDate date]] != NSOrderedDescending) {
                NSLog(@"账户过期");
                
//                self.access_token = nil;
            }
        }
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (NSString *)description {
    NSMutableArray *tempMDict = [NSMutableArray arrayWithCapacity:5];
    
    for (NSString *property in [self propertiesWithClass:[self class]]) {
        [tempMDict addObject:property];
    }
    
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, [self dictionaryWithValuesForKeys:tempMDict.copy].description];
}

- (void)saveUserAccount {
    NSMutableDictionary *tempMDict = [NSMutableDictionary dictionaryWithCapacity:5];
    
    for (NSString *property in [self propertiesWithClass:[self class]]) {
        id value = [self valueForKey:property];
        if (value) {
            [tempMDict setObject:value forKey:property];
        } /*else {
            [tempMDict setObject:[NSNull null] forKey:property];
        }*/
    }
    
    [tempMDict removeObjectForKey:@"expires_in"];
    
    [[NSUserDefaults standardUserDefaults] setObject:tempMDict.copy forKey:kSHUserAccount];
    NSLog(@"用户账户保存成功 %@", NSHomeDirectory());
}

- (void)deleteUserAccount {
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kSHUserAccount];
}

- (void)setExpires_in:(NSTimeInterval)expires_in {
    _expires_in = expires_in;
    
    _expiresDate = [NSDate dateWithTimeIntervalSinceNow:expires_in - 10];
}

- (void)setAccess_token:(NSString *)access_token {
    _access_token = access_token;

    if (access_token == nil) {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:kSHUserAccount];
    }
}

- (BOOL)access_tokenHasEffective {
    return [self.expiresDate compare:[NSDate date]] == NSOrderedDescending ? YES : NO;
}

/*****************************************************/
- (NSArray *)propertiesWithClass:(Class)cls {
    NSMutableArray *propertyMArray = [NSMutableArray array];
    
    unsigned int outCount = 0;
    
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    
    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        
        NSString *key = [[NSString alloc] initWithUTF8String:name];
        
        [propertyMArray addObject:key];
    }
    
    return propertyMArray.copy;
}

@end
