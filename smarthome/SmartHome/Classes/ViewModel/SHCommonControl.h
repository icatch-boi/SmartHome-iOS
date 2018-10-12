//
//  SHCommonControl.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHCommonControl : NSObject

- (void)addObserver:(ICatchEventID)eventTypeId
          listener:(Listener *)listener
       isCustomize:(BOOL)isCustomize camera:(SHCameraObject *)cameraObj;
- (void)removeObserver:(ICatchEventID)eventTypeId
             listener:(Listener *)listener
          isCustomize:(BOOL)isCustomize camera:(SHCameraObject *)cameraObj;
- (void)scheduleLocalNotice:(NSString *)message;
- (double)freeDiskSpaceInKBytes;
- (NSString *)translateSize:(unsigned long long)sizeInKB;

@end
