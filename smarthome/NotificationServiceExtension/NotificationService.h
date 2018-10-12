//
//  NotificationService.h
//  NotificationServiceExtension
//
//  Created by ZJ on 2017/11/3.
//  Copyright © 2017年 ZJ. All rights reserved.
//
#import <Foundation/Foundation.h>
#ifdef NSFoundationVersionNumber_iOS_9_x_Max

#import <UserNotifications/UserNotifications.h>

@interface NotificationService : UNNotificationServiceExtension

@end

#endif

