//
//  SHCameraObserver.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHObserver.h"

@implementation SHObserver

+ (instancetype)cameraObserverWithListener:(Listener *)listener1 eventType:(ICatchEventID)eventType1 isCustomized:(BOOL)isCustomized1 isGlobal:(BOOL)isGlobal1 {
    SHObserver *observer = [[self alloc] init];
    
    observer.listener = listener1;
    observer.eventType = eventType1;
    observer.isCustomized = isCustomized1;
    observer.isGlobal = isGlobal1;
    
    return observer;
}
@end
