//
//  NotificationService.m
//  NotificationServiceExtension
//
//  Created by ZJ on 2017/11/3.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "NotificationService.h"

#ifdef NSFoundationVersionNumber_iOS_9_x_Max

#import "SHShareCamera.h"
#import "SHUtilsMacro.h"
@interface NotificationService ()

@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;

@end

@implementation NotificationService

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
//    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    [self test];
    
#if 0
    NSString *attachmentPath = [self parseNotification:self.bestAttemptContent.userInfo][@"attachment"];
    [self loadAttachmentForUrlString:attachmentPath completionHandle:^{
//        [self apnsDeliverWith:request];
        self.contentHandler(self.bestAttemptContent);
    }];
#else
    // fix SH-912
    self.contentHandler(self.bestAttemptContent);
#endif
    [self updateBadgeNumber];
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
    [self test];
    self.contentHandler(self.bestAttemptContent);
}

- (void)loadAttachmentForUrlString:(NSString *)urlStr completionHandle:(void(^)(void))completionHandler {
    if (urlStr == nil || urlStr.length == 0) {
        completionHandler();
        return;
    }
    
    NSString *fileExt = urlStr.pathExtension;
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *attachmentURL = [NSURL URLWithString:urlStr];
    
    // download
    NSURLSessionTask *task = [session dataTaskWithURL:attachmentURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data && error == nil) {
            NSString * localPath = [NSString stringWithFormat:@"%@/myAttachment.%@", NSTemporaryDirectory(), fileExt];
            if ([data writeToFile:localPath atomically:YES]) {
                
                NSError *attachmentError = nil;
                UNNotificationAttachment * attachment = [UNNotificationAttachment attachmentWithIdentifier:@"myAttachment" URL:[NSURL fileURLWithPath:localPath] options:nil error:&attachmentError];
                
                if (attachmentError) {
                    NSLog(@"%@", attachmentError.localizedDescription);
                } else {
                    self.bestAttemptContent.attachments = @[attachment];
                    self.bestAttemptContent.launchImageName = [@"myAttachment." stringByAppendingString:fileExt];
                }
            }
        }
        
        completionHandler();
    }];
    [task resume];
}

- (void)apnsDeliverWith:(UNNotificationRequest *)request {
    //service extension sdk
    //upload to calculate delivery rate
    //please set the same AppKey as your JPush
//    [JPushNotificationExtensionService jpushSetAppkey:@"757252cf30f8e05598e91b58"];
//    [JPushNotificationExtensionService jpushReceiveNotificationRequest:request with:^ {
//        NSLog(@"apns upload success");
//        self.contentHandler(self.bestAttemptContent);
//    }];
}

- (void)test {
    self.bestAttemptContent.title = NSLocalizedString(@"kNotificationInfoTitle", nil);
    
//    NSDictionary *aps = self.bestAttemptContent.userInfo[@"aps"];
    NSDictionary *aps = [self parseNotification:self.bestAttemptContent.userInfo];
    
    NSString *devID = [NSString stringWithFormat:@"%@", aps[@"devID"]];
    NSString *time = [NSString stringWithFormat:@"%@", aps[@"time"]];
    NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];

    devID = [self getCameraName:devID];
    devID = devID ? devID : @"";
    
    NSString *str = nil;
    if ([msgType isEqualToString:@"100"]) {
        str = NSLocalizedString(@"kMonitorTypePir", nil);
    } else if ([msgType isEqualToString:@"102"]) {
        str = NSLocalizedString(@"ALERT_LOW_BATTERY", nil);
    } else if ([msgType isEqualToString:@"103"]) {
        str = NSLocalizedString(@"CARD_FULL", nil);
    } else if ([msgType isEqualToString:@"201"]) {
        self.bestAttemptContent.sound = [UNNotificationSound soundNamed:@"test1.caf"];
        
        if ([self checkNotificationWhetherOverdue:aps]) {
            self.bestAttemptContent.body = NSLocalizedString(@"kDoorbellOverdueTips", nil);
        } else {
            self.bestAttemptContent.body = NSLocalizedString(@"kDoorbellTips", nil);
        }
    } else if ([msgType isEqualToString:@"202"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:@"%@ %@", devID, NSLocalizedString(@"kDetectSome", nil)];
    } else if ([msgType isEqualToString:@"203"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:@"%@ %@", devID, NSLocalizedString(@"kNotDetectSome", nil)];
    } else if ([msgType isEqualToString:@"204"]) {
        str = [NSString stringWithFormat:@"Push message test, msgID: %@", aps[@"msgID"]];
    } else if ([msgType isEqualToString:@"104"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kSDCardErrorTipsInfo", nil), devID, time];
    } else if ([msgType isEqualToString:@"105"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kDeviceRemoveTipsInfo", nil), devID];
    }
    
    if (str != nil) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kNotificationContentInfo", nil), devID, time, str];
    }
}

- (NSDictionary *)parseNotification:(NSDictionary *)userInfo {
    if (userInfo == nil) {
        return nil;
    }
    
    NSDictionary *aps = userInfo[@"aps"];
    NSString *alert = aps[@"alert"];
    NSDictionary *alertDict = [NSJSONSerialization JSONObjectWithData:[alert dataUsingEncoding:NSUTF8StringEncoding] options:0 error:NULL];
    
    return alertDict;
}

- (BOOL)checkNotificationWhetherOverdue:(NSDictionary *)aps {
    NSString *time = aps[@"time"];
    
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *startDate = [dateformatter dateFromString:time];
    NSDate *endDate = [NSDate date];
    
    NSTimeInterval interval = [endDate timeIntervalSinceDate:startDate];
    
    BOOL overdue = NO;
    
    if (interval > 120) {
        overdue = YES;
    }
    
    return overdue;
}

- (NSString *)getCameraName:(NSString *)cameraUid {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSData *data  = [userDefault objectForKey:kShareCameraInfoKey];
    NSArray *camerasArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    __block NSString *cameraName = nil;

    [camerasArray enumerateObjectsUsingBlock:^(SHShareCamera *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cameraUid isEqualToString:cameraUid]) {
            cameraName = obj.cameraName;
            *stop = YES;
        }
    }];
    
    NSLog(@"cameraName: %@", cameraName);
    return cameraName;
}

- (void)updateBadgeNumber {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSNumber *count = [defaults objectForKey:kRecvNotificationCount];
    NSInteger currentCount = 1;
    
    currentCount += count.integerValue;
    
    [defaults setObject:@(currentCount) forKey:kRecvNotificationCount];
}

@end

#endif

