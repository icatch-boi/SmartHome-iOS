//
//  SHCommonControl.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHCommonControl.h"
#include <sys/param.h>
#include <sys/mount.h>

@implementation SHCommonControl

- (void)addObserver:(ICatchEventID)eventTypeId
           listener:(Listener *)listener
        isCustomize:(BOOL)isCustomize camera:(SHCameraObject *)cameraObj {
    SHLogInfo(SHLogTagAPP, @"Add Observer: [id]0x%x, [listener]%p", eventTypeId, listener);
    [cameraObj.sdk addObserver:eventTypeId listener:listener isCustomize:isCustomize];
}

- (void)removeObserver:(ICatchEventID)eventTypeId
              listener:(Listener *)listener
           isCustomize:(BOOL)isCustomize camera:(SHCameraObject *)cameraObj {
    SHLogInfo(SHLogTagAPP, @"Remove Observer: [id]0x%x, [listener]%p", eventTypeId, listener);
    [cameraObj.sdk removeObserver:eventTypeId listener:listener isCustomize:isCustomize];
}

- (void)scheduleLocalNotice:(NSString *)message
{
    UIApplication  *app = [UIApplication sharedApplication];
    UILocalNotification *alarm = [[UILocalNotification alloc] init];
    if (alarm) {
        alarm.fireDate = [NSDate date];
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.alertBody = message;
        alarm.soundName = UILocalNotificationDefaultSoundName;
        
        [app scheduleLocalNotification:alarm];
    }
}

- (double)freeDiskSpaceInKBytes
{
    struct statfs buf;
    long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = buf.f_bsize * buf.f_bfree / 1024 - 204800; // Minus 200MB to adjust the real size
    }
    
    return freeSpace;
}

- (NSString *)translateSize:(unsigned long long)sizeInKB
{
    NSString *humanDownloadFileSize = nil;
    double temp = (double)sizeInKB/1024; // MB
    if (temp > 1024) {
        temp /= 1024;
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fGB", temp];
    } else {
        humanDownloadFileSize = [NSString stringWithFormat:@"%.2fMB", temp];
    }
    return humanDownloadFileSize;
}

@end
