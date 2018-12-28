// SHCameraHelper.m

/**************************************************************************
 *
 *       Copyright (c) 2014-2018年 by iCatch Technology, Inc.
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
 
 // Created by zj on 2018/4/24 下午5:07.
    

#import "SHCameraHelper.h"
#import <objc/runtime.h>

@implementation SHCameraHelper

#if USE_ENCRYP
+ (instancetype)cameraWithName:(NSString *)cameraName cameraToken:(NSString *)cameraToken cameraUidToken:(NSString *)cameraUidToken devicePassword:(NSString *)devicePassword thumbnail:(UIImage *)thumnail id:(NSString *)cameraId operable:(int)operable {
#else
+ (instancetype)cameraWithName:(NSString *)cameraName cameraUid:(NSString *)cameraUid devicePassword:(NSString *)devicePassword id:(NSString *)cameraId thumbnail:(UIImage *)thumnail operable:(int)operable {
#endif
    SHCameraHelper *camera = [[SHCameraHelper alloc] init];
    
    camera.cameraName = cameraName;
#if USE_ENCRYP
    camera.cameraToken = cameraToken;
    camera.cameraUidToken = cameraUidToken;
#else
    camera.cameraUid = cameraUid;
#endif
    camera.devicePassword = devicePassword;
    camera.id = cameraId;
    camera.thumnail = thumnail;
    camera.operable = operable;
    
    return camera;
}

- (NSString *)description {
    //NSArray *properties = [self propertiesWithClass:self.class];
    
    //return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, [self dictionaryWithValuesForKeys:properties].description];
    return  [NSString stringWithFormat:@"SHCameraHelper -\n name : %@ \n, uuid : %@ \n, password : %@ operate : %d\n, addTime: %@\n", _cameraName, _cameraUid, _devicePassword, _operable, _addTime];
}

/********************************************************/
- (NSArray *)propertiesWithClass:(Class)cls {
    NSMutableArray *propertyMArray = [NSMutableArray array];
    uint outCount = 0;
    
    objc_property_t *properties = class_copyPropertyList(cls, &outCount);
    
    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        
        NSString *key = [[NSString alloc] initWithUTF8String:name];
        
        if (key != nil) {
            [propertyMArray addObject:key];
        }
    }
    
    return propertyMArray.copy;
}

@end
