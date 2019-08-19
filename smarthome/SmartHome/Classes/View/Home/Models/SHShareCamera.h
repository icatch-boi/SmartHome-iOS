//
//  SHShareCamera.h
//  SmartHome
//
//  Created by ZJ on 2018/1/11.
//  Copyright © 2018年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHShareCamera : NSObject <NSCoding>

@property (nonatomic, copy) NSString *cameraUid;
@property (nonatomic, copy) NSString *cameraName;
@property (nonatomic, copy) NSString *deviceID;

@end
