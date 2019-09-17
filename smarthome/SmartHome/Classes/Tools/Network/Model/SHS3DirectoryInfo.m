// SHS3DirectoryInfo.m

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
 
 // Created by zj on 2019/9/11 4:44 PM.
    

#import "SHS3DirectoryInfo.h"

@interface SHS3DirectoryInfo ()

@property (nonatomic, copy) NSString *bucket;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *portrait;
@property (nonatomic, copy) NSString *faces;
@property (nonatomic, copy) NSString *cover;
@property (nonatomic, copy) NSString *messages;
@property (nonatomic, copy) NSString *files;

@end

@implementation SHS3DirectoryInfo

+ (instancetype)s3DirectoryInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (NSString *)description {
    NSMutableArray *tempMDict = [NSMutableArray array];
    
    for (NSString *property in [SHTool propertiesWithClass:[self class]]) {
        [tempMDict addObject:property];
    }
    
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, [self dictionaryWithValuesForKeys:tempMDict.copy].description];
}

- (NSDictionary *)conversionToDictionary {
    NSMutableDictionary *tempMDict = [NSMutableDictionary dictionary];
    
    for (NSString *property in [SHTool propertiesWithClass:[self class]]) {
        id value = [self valueForKey:property];
        if (value) {
            [tempMDict setObject:value forKey:property];
        } /*else {
           [tempMDict setObject:[NSNull null] forKey:property];
           }*/
    }
    
    return tempMDict.copy;
}

@end
