// CoreDataHandler+SHCamera.m

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
 
 // Created by zj on 2018/3/27 上午10:49.
    

#import "CoreDataHandler+SHCamera.h"
#import "SHCameraHelper.h"
#import <SHAccountManagementKit/SHAccountManagementKit.h>
#import "XJLocalAssetHelper.h"
#import "SHMessageCountManager.h"

@implementation CoreDataHandler (SHCamera)

- (NSArray *)fetchedCamera {
    NSMutableArray *tempMArray = [NSMutableArray array];
    NSMutableArray *overdueMArray = [NSMutableArray array];
    
    NSError *error = nil;
    if (![[self fetchedResultsController] performFetch:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    }
    
    if (self.fetchedResultsController.sections.count > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController.sections objectAtIndex:0];
        SHLogDebug(SHLogTagAPP, @"SHCamera num : %lu",(unsigned long)[sectionInfo numberOfObjects]);
        
        if([sectionInfo numberOfObjects] > 0) {
            
            for (int i = 0; i < [sectionInfo numberOfObjects]; ++i) {
                //行数据
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
                SHCamera *camera = (SHCamera *)[self.fetchedResultsController objectAtIndexPath:indexPath];
                SHLogDebug(SHLogTagAPP, @"uid: %@ - name: %@ create time is %@", camera.cameraUid, camera.cameraName,camera.createTime);
#if 0
                if ([self checkCameraExpires:camera]) {
                    [overdueMArray addObject:camera];
                } else {
                    [tempMArray addObject:camera];
                }
#else
                [tempMArray addObject:camera];
#endif
            }
        }
    }
    
    [self deleteOverdueData:overdueMArray.copy];
    
    return tempMArray.copy;
}

- (BOOL)checkCameraExpires:(SHCamera *)camera {
    NSDate *currentDate = [NSDate date];
    NSString *camTime = camera.createTime;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyyMMdd HHmmss"];
    NSDate *camDate = [df dateFromString:camTime];
    camDate = [camDate dateByAddingTimeInterval:kDataBaseFileStorageTime];
    
    if ([currentDate compare:camDate] == NSOrderedAscending) {
        return NO;
    } else {
        return YES;
    }
}

- (void)deleteOverdueData:(NSArray *)overdueArr {
    WEAK_SELF(self);
    [overdueArr enumerateObjectsUsingBlock:^(SHCamera *camera, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![SHTutkHttp unregisterDevice:camera.cameraUid]) {
            SHLogError(SHLogTagAPP, @"unregisterDevice failed.");
        }
        
        [weakself deleteCamera:camera];
    }];
}

- (NSArray *)getManagedObjectByCamera:(SHCamera *)camera {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:kEntityName
                                              inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"cameraUid = %@", camera.cameraUid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error) {
        return fetchedObjects;
    } else {
        return nil;
    }
}

- (BOOL)containsCamera:(SHCamera *)camera {
    NSArray *fetchedObjects = [self getManagedObjectByCamera:camera];
    
    if (fetchedObjects && fetchedObjects.count > 0) {
        return YES;
    } else {
        SHLogError(SHLogTagAPP, @"fetch failed.");
        return NO;
    }
}

- (BOOL)deleteCamera:(SHCamera *)camera {
    BOOL isSuccess = YES;

    if (camera == nil) {
        SHLogError(SHLogTagAPP, @"camera is nil.");
        return NO;
    }
    
    NSString *cameraUid = camera.cameraUid;
    [self.managedObjectContext deleteObject:camera];
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
        
        isSuccess = NO;
#ifdef DEBUG
        abort();
#endif
    } else {
        SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
        
        [self cleanDeviceDataWithUid:cameraUid];
    }
    
    return isSuccess;
}

- (void)cleanDeviceDataWithUid:(NSString *)cameraUid {
    // clean cache device before remove local db.
    [self cleanMemoryCacheWithUid:cameraUid];
    [self removeCacheThumbnailWithUid:cameraUid];
    
    [[XJLocalAssetHelper sharedLocalAssetHelper] deleteLocalAllAssetsWithKey:cameraUid completionHandler:^(BOOL success) {
        SHLogInfo(SHLogTagAPP, @"Delete local all asset is success: %d", success);
    }];
    
    [SHMessageCountManager removeMessageCountCacheWithCameraUID:cameraUid];
}

- (void)removeCacheThumbnailWithUid:(NSString *)cameraUid {
    NSString *databaseName = [cameraUid.md5 stringByAppendingString:@".db"];
    NSString *databasePath = [SHTool databasePathWithName:databaseName];
    
    [SHTool removeFileWithPath:databasePath];
}

- (BOOL)addCamera:(SHCameraHelper *)cameraInfo {
    __block BOOL isSuccess = YES;
    
    WEAK_SELF(self);
    [self.managedObjectContext performBlockAndWait:^{
        [SHSDK checkDeviceStatusWithUID:cameraInfo.cameraUid];
        isSuccess = [weakself addCameraDetailHandle:cameraInfo];
    }];
    
    return isSuccess;
}

- (BOOL)addCameraDetailHandle:(SHCameraHelper *)cameraInfo {
    // when uid is nil, don't add camera.
    if (cameraInfo.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        return NO;
    }
    
    BOOL isSuccess = YES;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:kEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"cameraUid = %@", cameraInfo.cameraUid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        SHLogInfo(SHLogTagAPP, @"Already have one camera, update camera info.");
        
        SHCamera *camera = (SHCamera *)fetchedObjects.firstObject;
        camera.cameraName = cameraInfo.cameraName ? cameraInfo.cameraName : camera.cameraName;
        camera.cameraUid = cameraInfo.cameraUid ? cameraInfo.cameraUid : camera.cameraUid;
        camera.devicePassword = cameraInfo.devicePassword ? cameraInfo.devicePassword : camera.devicePassword;
        camera.id = cameraInfo.id ? cameraInfo.id : camera.id;
        camera.thumbnail = cameraInfo.thumnail ? cameraInfo.thumnail : camera.thumbnail;
        camera.operable = cameraInfo.operable;
        camera.hwversionid = cameraInfo.deviceInfo.hwversionid;
        camera.versionid = cameraInfo.deviceInfo.versionid;

        camera.createTime = cameraInfo.addTime;
        // Save data to sqlite
        NSError *error = nil;
        if (![camera.managedObjectContext save:&error]) {
            SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
            
            isSuccess = NO;
#ifdef DEBUG
            abort();
#endif
        } else {
            SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
            
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateDeviceInfoNotification object:cameraInfo.cameraUid];
            [SHTutkHttp registerDevice:camera];
        }
    } else {
        SHLogInfo(SHLogTagAPP, @"Create a camera");
        SHCamera *savedCamera = (SHCamera *)[NSEntityDescription insertNewObjectForEntityForName:kEntityName inManagedObjectContext:self.managedObjectContext];

        savedCamera.cameraName = cameraInfo.cameraName;
        savedCamera.cameraUid = cameraInfo.cameraUid;
        savedCamera.devicePassword = cameraInfo.devicePassword;
        savedCamera.id = cameraInfo.id;
        savedCamera.thumbnail = cameraInfo.thumnail;
        savedCamera.operable = cameraInfo.operable;
        savedCamera.hwversionid = cameraInfo.deviceInfo.hwversionid;
        savedCamera.versionid = cameraInfo.deviceInfo.versionid;
#if 0
        NSDate *date = [NSDate date];
        NSTimeInterval sec = [date timeIntervalSinceNow];
        NSDate *currentDate = [[NSDate alloc] initWithTimeIntervalSinceNow:sec];
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyyMMdd HHmmss"];
        savedCamera.createTime = [df stringFromDate:currentDate];
        SHLogInfo(SHLogTagAPP, @"Create time is %@", savedCamera.createTime);
#else
        savedCamera.createTime = cameraInfo.addTime;
#endif
        // Save data to sqlite
        NSError *error = nil;
        if (![savedCamera.managedObjectContext save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
             */
            SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
            
            isSuccess = NO;
#ifdef DEBUG
            abort();
#endif
        } else {
            SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
            [SHTutkHttp registerDevice:savedCamera];
        }
    }
    
    return isSuccess;
}

- (BOOL)updateCameraThumbnail:(SHCameraHelper *)cameraInfo {
    __block BOOL isSuccess = YES;
    
    WEAK_SELF(self);
    [self.managedObjectContext performBlockAndWait:^{
        isSuccess = [weakself updateCameraThumbnailHandler:cameraInfo];
    }];
    
    return isSuccess;
}

- (BOOL)updateCameraThumbnailHandler:(SHCameraHelper *)cameraInfo {
    // when uid is nil, don't update camera.
    if (cameraInfo.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        return NO;
    }
    
    if (cameraInfo.thumnail == nil) {
        SHLogError(SHLogTagAPP, @"camera thumnail is nil.");
        return NO;
    }
    
    BOOL isSuccess = YES;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:kEntityName inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSPredicate *predicate = [NSPredicate
                              predicateWithFormat:@"cameraUid = %@", cameraInfo.cameraUid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (!error && fetchedObjects && fetchedObjects.count>0) {
        SHLogInfo(SHLogTagAPP, @"Already have one camera, update camera info.");
        
        SHCamera *camera = (SHCamera *)fetchedObjects.firstObject;
        
        camera.thumbnail = cameraInfo.thumnail ? cameraInfo.thumnail : camera.thumbnail;
        
        // Save data to sqlite
        NSError *error = nil;
        if (![camera.managedObjectContext save:&error]) {
            SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
            
            isSuccess = NO;
#ifdef DEBUG
            abort();
#endif
        } else {
            SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
//            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateDeviceInfoNotification object:cameraInfo.cameraUid];
        }
    }
    
    return isSuccess;
}

- (void)deleteAllCameras {
    SHLogTRACE();
    
    NSArray *cameras = [self fetchedCamera];
    WEAK_SELF(self);
    [cameras enumerateObjectsUsingBlock:^(SHCamera *camera, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![SHTutkHttp unregisterDevice:camera.cameraUid]) {
            SHLogError(SHLogTagAPP, @"unregisterDevice failed.");
        }
        
        [weakself cleanMemoryCacheWithUid:camera.cameraUid];
        [weakself deleteCamera:camera];
    }];
}

- (void)cleanMemoryCacheWithUid:(NSString *)uid {
    SHCameraManager *manager = [SHCameraManager sharedCameraManger];
    SHCameraObject *obj = [manager getSHCameraObjectWithCameraUid:uid];
    [[SHCameraManager sharedCameraManger] removeSHCameraObject:obj];
}

- (void)updateLocalCamerasWithRemoteCameras:(NSArray *)remoteCameras {
    NSArray *localCams = [self fetchedCamera];
    
    WEAK_SELF(self);
    [localCams enumerateObjectsUsingBlock:^(SHCamera *localCam, NSUInteger idx, BOOL * _Nonnull stop) {
        [weakself checkRemoteContainsCamera:localCam remoteCameras:remoteCameras];
    }];
}

- (void)checkRemoteContainsCamera:(SHCamera *)localCamera remoteCameras:(NSArray *)remoteCameras {
    __block BOOL exist = NO;
    
    [remoteCameras enumerateObjectsUsingBlock:^(Camera *remoteCam, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([localCamera.id isEqualToString:remoteCam.id]) {
            exist = YES;
            *stop = YES;
        }
    }];
    
    if (!exist) {
        if (![SHTutkHttp unregisterDevice:localCamera.cameraUid]) {
            SHLogError(SHLogTagAPP, @"unregisterDevice failed.");
        }
        
        if ([self rightAwayUpdateLocalCamera]) {
            [self cleanMemoryCacheWithUid:localCamera.cameraUid];
            [self deleteCamera:localCamera];
        } else {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"needSyncDataFromServer"];
        }
    }
}

- (BOOL)rightAwayUpdateLocalCamera {
    ZJSlidingDrawerViewController *slidingVC = (ZJSlidingDrawerViewController *)[[UIApplication sharedApplication] keyWindow].rootViewController;
    UINavigationController *mainVC = (UINavigationController *)slidingVC.mainVC;
    UIViewController *visibleVC = mainVC.visibleViewController;
    
    SHLogInfo(SHLogTagAPP, @"current visibleViewController: %@", visibleVC);
    if ([NSStringFromClass([visibleVC class]) isEqualToString:@"UIAlertController"]) {
        UIAlertController *vc = (UIAlertController *)visibleVC;
        if ([vc.message isEqualToString:NSLocalizedString(@"kDeleteDeviceDescription", nil)]) {
            return YES;
        }
    }
    
    if ([NSStringFromClass([visibleVC class]) isEqualToString:@"SHHomeTableViewController"]) {
        return YES;
    } else {
        return NO;
    }
}

@end
