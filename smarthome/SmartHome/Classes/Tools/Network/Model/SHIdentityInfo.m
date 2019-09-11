// SHIdentityInfo.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2019 by iCatch Technology, Inc.
 *
 *  This software is copyrighted by and is the property of iCatch
 *  Technology, Inc.. All rights are reserved by iCatch Technology, Inc..
 *  This software may only be used in accordance with the corresponding
 *  license agreement. Any unauthorized use, duplication, distribution,
 *  or disclosure of this software is expressly forbidden.
 *
 *  This Copyright notice MUST not be removed or modified without prior
 *  written consent of iCatch Technology, Inc..
 *
 *  iCatch Technology, Inc. reserves the right to modify this software
 *  without notice.
 *
 *  iCatch Technology, Inc.
 *  19-1, Innovation First Road, Science-Based Industrial Park,
 *  Hsin-Chu, Taiwan, R.O.C.
 *
 **************************************************************************/
 
 // Created by zj on 2019/9/10 2:59 PM.
    

#import "SHIdentityInfo.h"
#import <objc/runtime.h>

@interface SHIdentityInfo ()

@property (nonatomic, copy) NSString *IdentityId;
@property (nonatomic, copy) NSString *IdentityPoolId;
@property (nonatomic, copy) NSString *Token;

@end

@implementation SHIdentityInfo

+ (instancetype)identityInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self && dict) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (NSDictionary *)conversionToDictionary {
    NSMutableDictionary *tempMDict = [NSMutableDictionary dictionary];
    
    for (NSString *property in [self propertiesWithClass:[self class]]) {
        id value = [self valueForKey:property];
        if (value) {
            [tempMDict setObject:value forKey:property];
        } /*else {
           [tempMDict setObject:[NSNull null] forKey:property];
           }*/
    }
    
    return tempMDict.copy;
}

/******************************************************************/
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
