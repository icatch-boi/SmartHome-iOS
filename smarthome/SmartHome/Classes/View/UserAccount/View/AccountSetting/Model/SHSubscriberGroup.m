// SHSubscriberGroup.m

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
 
 // Created by zj on 2019/7/23 6:05 PM.
    

#import "SHSubscriberGroup.h"
#import "SHNetworkManager+SHCamera.h"
#import "SVProgressHUD.h"
#import "SHSubscriberInfo.h"

@interface SHSubscriberGroup ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *cameraID;
@property (nonatomic, strong) NSArray<SHSubscriberInfo *> *subscribers;

@end

@implementation SHSubscriberGroup

+ (void)loadSubscriberGroupData:(void (^)(NSArray<SHSubscriberGroup *> *subscriberGroups))finished {
    NSMutableArray *temp = [NSMutableArray array];
    
    NSArray *camers = [SHCameraManager sharedCameraManger].smarthomeCams.copy;
    
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD show];

    dispatch_group_t groupS = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("com.icatchtek.Subscriber", DISPATCH_QUEUE_CONCURRENT);
    [camers enumerateObjectsUsingBlock:^(SHCameraObject*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.camera.operable == 1) {
            dispatch_group_enter(groupS);
            
            dispatch_async(queue, ^{
                SHSubscriberGroup *group = [SHSubscriberGroup new];
                group.name = obj.camera.cameraName;
                group.cameraID = obj.camera.id;
                
                [temp addObject:group];
                
                [[SHNetworkManager sharedNetworkManager] getCameraSubscribersWithCameraID:obj.camera.id status:0x100 completion:^(BOOL isSuccess, id  _Nullable result) {
                    if (isSuccess) {
//                        group.subscribers = [NSArray arrayWithArray:result];
                        group.subscribers = [self subscriberInfo:result];
                    } else {
                        Error *error = result;
                        SHLogError(SHLogTagAPP, @"getCameraSubscribersWithCameraID failed, error: %@", error.error_description);
                    }
                    
                    dispatch_group_leave(groupS);
                }];
            });
        }
    }];
    
    dispatch_group_notify(groupS, dispatch_get_main_queue(), ^{
        [SVProgressHUD dismiss];

        if (finished) {
            finished(temp.copy);
        }
    });
}

+ (NSArray<SHSubscriberInfo *> *)subscriberInfo:(NSArray *)subscribers {
    NSMutableArray *temp = [NSMutableArray array];
    
    [subscribers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SHSubscriberInfo *info = [SHSubscriberInfo new];
        info.subscriber = obj;
        
        [temp addObject:info];
    }];
    
    return temp.copy;
}

+ (instancetype)subscriberGroupWithName:(NSString *)name cameraID:(NSString *)cameraID subscribers:(NSArray<SHSubscriberInfo *> *)subscribers {
    SHSubscriberGroup *group = [SHSubscriberGroup new];
    
    group.name = name;
    group.cameraID = cameraID;
    group.subscribers = [NSArray arrayWithArray:subscribers];
    
    return group;
}

@end
