//
//  SHSHCameraObjManager.h
//  SmartHome
//
//  Created by ZJ on 2017/4/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHCameraObjManager : NSObject

@property (nonatomic) SHCameraObject *shCameraObj;
@property (nonatomic) BOOL isConnect;
@property (nonatomic) BOOL readyGoToFullScreen;

@end
