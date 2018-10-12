//
//  SHCameraManager.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SHCameraObject.h"

@interface SHCameraManager : NSObject

@property (nonatomic, readonly) NSMutableArray *smarthomeCams;

+ (instancetype)sharedCameraManger;
- (instancetype)init __attribute__((unavailable("Disabled. Please use the sharedCameraManger methods instead.")));

- (void)addSHCameraObject:(SHCamera *)shCamera;
- (void)removeSHCameraObject:(SHCameraObject *)shCameraobj;
- (SHCameraObject *)getSHCameraObjectWithCameraUid:(NSString *)uid;
- (void)removeAllCameraObjects;
- (void)unmappingAllCamera;

@end
