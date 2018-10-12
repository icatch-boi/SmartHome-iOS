//
//  SHCameraObserver.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHObserver : NSObject

@property(nonatomic) ICatchEventID eventType;
@property(nonatomic) Listener *listener;
@property(nonatomic) BOOL isCustomized;
@property(nonatomic) BOOL isGlobal;

+ (instancetype)cameraObserverWithListener:(Listener *)listener1
                                 eventType:(ICatchEventID)eventType1
                              isCustomized:(BOOL)isCustomized1
                                  isGlobal:(BOOL)isGlobal1;

@end
