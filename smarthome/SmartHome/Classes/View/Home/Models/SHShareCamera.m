//
//  SHShareCamera.m
//  SmartHome
//
//  Created by ZJ on 2018/1/11.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import "SHShareCamera.h"
#import <objc/runtime.h>

@implementation SHShareCamera

- (void)encodeWithCoder:(NSCoder *)encoder
{
//    [encoder encodeObject:self.cameraUid forKey:@"cameraUid"];
//    [encoder encodeObject:self.cameraName forKey:@"cameraName"];
    for (NSString *property in [self propertiesWithClass:[self class]]) {
        [encoder encodeObject:[self valueForKey:property] forKey:property];
    }
}

- (id)initWithCoder:(NSCoder *)decoder
{
    if(self = [super init])
    {
//        self.cameraUid = [decoder decodeObjectForKey:@"cameraUid"];
//        self.cameraName = [decoder decodeObjectForKey:@"cameraName"];
        for (NSString *property in [self propertiesWithClass:[self class]]) {
            [self setValue:[decoder decodeObjectForKey:property] forKey:property];
        }
    }
    return  self;
}

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
