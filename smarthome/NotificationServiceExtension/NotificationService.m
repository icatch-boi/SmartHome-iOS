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
#import "SHFaceInfo.h"
static NSString * const kFaceInfoPath = @"v1/users/faces/info";
static NSString * const kFaceimagePath = @"v1/devices/faceimage";
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
    self.bestAttemptContent.title = NSLocalizedString(@"kNotificationInfoTitle", nil);

    if ([self.bestAttemptContent.userInfo.allKeys containsObject:@"devID"]) {
        NSDictionary *userInfo = self.bestAttemptContent.userInfo;
        if ([userInfo.allKeys containsObject:@"msgType"] && [userInfo[@"msgType"] intValue] == 202) {
            self.bestAttemptContent.sound = [UNNotificationSound soundNamed:@"test1.caf"];
        }
        
        if ([self.bestAttemptContent.userInfo.allKeys containsObject:@"attachment"]) {
            NSString *attachmentPath = self.bestAttemptContent.userInfo[@"attachment"];
            [self loadAttachmentForUrlString:attachmentPath completionHandle:^{
                self.contentHandler(self.bestAttemptContent);
            }];
        } else {
            self.contentHandler(self.bestAttemptContent);
        }
    } else {
        [self test];
        
        NSDictionary *aps = [self parseNotification:self.bestAttemptContent.userInfo];
        int msgType = [aps[@"msgType"] intValue];
        if (msgType == PushMessageTypeFaceRecognition) {
            return;
        }
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)serviceExtensionTimeWillExpire {
    // Called just before the extension will be terminated by the system.
    // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.

    self.bestAttemptContent.title = NSLocalizedString(@"kNotificationInfoTitle", nil);
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

- (void)test {
    self.bestAttemptContent.title = NSLocalizedString(@"kNotificationInfoTitle", nil);
    
    NSDictionary *aps = [self parseNotification:self.bestAttemptContent.userInfo];
    
    NSString *devID = [NSString stringWithFormat:@"%@", aps[@"devID"]];
    NSString *time = [NSString stringWithFormat:@"%@", aps[@"time"]];
    NSString *msgType = [NSString stringWithFormat:@"%@", aps[@"msgType"]];
    time = [self checkRecvTime:time];
    
    NSString *tempDevID = devID;
    devID = [self getCameraName:devID];
    devID = devID ? devID : [tempDevID substringToIndex:5];
    
    NSString *str = nil;
    if ([msgType isEqualToString:@"100"]) {
        str = NSLocalizedString(@"kMonitorTypePir", nil);
    } else if ([msgType isEqualToString:@"102"]) {
        str = NSLocalizedString(@"ALERT_LOW_BATTERY", nil);
    } else if ([msgType isEqualToString:@"110"]) {
        str = NSLocalizedString(@"kLowBatteryNotification", nil);
    } else if ([msgType isEqualToString:@"103"]) {
        str = NSLocalizedString(@"CARD_FULL", nil);
    } else if ([msgType isEqualToString:@"201"]) {
        self.bestAttemptContent.sound = [UNNotificationSound soundNamed:@"test1.caf"];
        
        if ([self checkNotificationWhetherOverdue:aps]) {
            self.bestAttemptContent.body = [NSString stringWithFormat:@"%@ %@", devID, NSLocalizedString(@"kDoorbellOverdueTips", nil)];
        } else {
            self.bestAttemptContent.body = [NSString stringWithFormat:@"%@ %@", devID, NSLocalizedString(@"kDoorbellTips", nil)];
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
    } else if ([msgType isEqualToString:@"106"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kDownloadUpgradePackageSuccess", nil), devID];
    }  else if ([msgType isEqualToString:@"107"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kDownloadUpgradePackageFailed", nil), devID];
    }  else if ([msgType isEqualToString:@"108"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kFWUpgradeSuccess", nil), devID];
    }  else if ([msgType isEqualToString:@"109"]) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kFWUpgradeFailed", nil), devID];
    } else if ([msgType isEqualToString:@"301"]) {
        self.bestAttemptContent.sound = [UNNotificationSound soundNamed:@"test1.caf"];
        self.bestAttemptContent.body = [NSString stringWithFormat:@"%@ %@", devID, NSLocalizedString(@"kDoorbellTips", nil)];
        
        [self recognitionResultHandleWithInfo:aps deviceName:devID];
    }
    
    if (str != nil) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kNotificationContentInfo", nil), devID, time, str];
    }
}

- (void)handleCompletion {
    self.contentHandler(self.bestAttemptContent);
}

- (void)recognitionResultHandleWithInfo:(NSDictionary *)info deviceName:(NSString *)deviceName {
    if (![info.allKeys containsObject:@"result"]) {
        [self handleCompletion];
        return;
    }
    
    int result = [info[@"result"] intValue];
    switch (result) {
        case 0:
            self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kDoorbellAnsweringDescription", nil), NSLocalizedString(@"kStranger", nil), deviceName];
            [self strangerHandleWithInfo:info deviceName:deviceName];
            break;
            
        case 1:
            [self recognitionSuccessHandleWithInfo:info deviceName:deviceName];
            break;
            
        case 2:
            break;
            
        default:
            break;
    }
    
    if (result != 1) {
        [self handleCompletion];
    }
}

- (void)recognitionSuccessHandleWithInfo:(NSDictionary *)info deviceName:(NSString *)deviceName {
    if (![info.allKeys containsObject:@"faceId"]) {
        [self handleCompletion];
        return;
    }
    
    NSArray *faceIDArr = info[@"faceId"];
    if (faceIDArr.count == 0) {
        [self handleCompletion];
        return;
    }
    
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *dict = [userDefault objectForKey:kUserAccount];
    NSLog(@"dict: %@", dict);
    
    if (![dict.allKeys containsObject:@"access_token"]) {
        [self handleCompletion];
        return;
    }
    
    NSString *token = [@"Bearer " stringByAppendingString:dict[@"access_token"]];
    
    NSURL *url = [NSURL URLWithString:[kServerBaseURL stringByAppendingString:[NSString stringWithFormat:@"%@?faceid=%@", kFaceInfoPath, faceIDArr.firstObject]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:kTimeoutInterval];
    request.HTTPMethod = @"get";
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SHLogError(SHLogTagAPP, @"连接错误: %@", error);
            [self handleCompletion];
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            SHLogInfo(SHLogTagAPP, @"json: %@", json);
            SHFaceInfo *faceInfo = [SHFaceInfo faceInfoWithDict:json];
            [self faceInfoHandleWithInfo:faceInfo deviceName:deviceName];
        } else {
            if (httpResponse.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
            }
            
            SHLogError(SHLogTagAPP, @"服务器内部错误");
            [self handleCompletion];
        }
        
    }] resume];
}

- (void)strangerHandleWithInfo:(NSDictionary *)info deviceName:(NSString *)deviceName {
    NSString *devID = [self getDeviceID:info[@"devID"]];
    if (devID.length == 0) {
        [self handleCompletion];
        return;
    }
    
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *dict = [userDefault objectForKey:kUserAccount];
    NSLog(@"dict: %@", dict);
    
    if (![dict.allKeys containsObject:@"access_token"]) {
        [self handleCompletion];
        return;
    }
    
    NSString *token = [@"Bearer " stringByAppendingString:dict[@"access_token"]];
    
    NSURL *url = [NSURL URLWithString:[kServerBaseURL stringByAppendingString:[NSString stringWithFormat:@"%@?id=%@", kFaceimagePath, devID]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:kTimeoutInterval];
    request.HTTPMethod = @"get";
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SHLogError(SHLogTagAPP, @"连接错误: %@", error);
            [self handleCompletion];
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            SHLogInfo(SHLogTagAPP, @"json: %@", json);
            SHFaceInfo *faceInfo = [SHFaceInfo faceInfoWithDict:json];
            [self faceInfoHandleWithInfo:faceInfo deviceName:deviceName];
        } else {
            if (httpResponse.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
            }
            
            SHLogError(SHLogTagAPP, @"服务器内部错误");
            [self handleCompletion];
        }
        
    }] resume];
}

- (void)faceInfoHandleWithInfo:(SHFaceInfo *)faceInfo deviceName:(NSString *)deviceName {
    if (faceInfo == nil) {
        [self handleCompletion];
        return;
    }
    
    NSString *name = faceInfo.name;
    if (name.length > 0) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kDoorbellAnsweringDescription", nil), name, deviceName];
    }
    
#if 0
    [self loadAttachmentForUrlString:faceInfo.url completionHandle:^{
        self.contentHandler(self.bestAttemptContent);
    }];
#else
    [self loacAttachmentWithFaceInfo:faceInfo completionHandle:^{
        self.contentHandler(self.bestAttemptContent);
    }];
#endif
}

- (void)loacAttachmentWithFaceInfo:(SHFaceInfo *)faceInfo completionHandle:(void(^)(void))completionHandler {
    
    [faceInfo getFaceImageWithCompletion:^(NSString * _Nullable faceImagePath) {
        if (faceImagePath != nil) {
            NSError *attachmentError = nil;
            UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"myAttachment" URL:[NSURL fileURLWithPath:faceImagePath] options:nil error:&attachmentError];
            
            if (attachmentError) {
                NSLog(@"%@", attachmentError.localizedDescription);
            } else {
                self.bestAttemptContent.attachments = @[attachment];
                self.bestAttemptContent.launchImageName = faceImagePath.lastPathComponent;
            }
        }
        
        completionHandler();
    }];
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
    
    if (userDefault == nil || data == nil || camerasArray == nil || camerasArray.count == 0) {
        return nil;
    }
    
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

- (NSString *)getDeviceID:(NSString *)cameraUid {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSData *data  = [userDefault objectForKey:kShareCameraInfoKey];
    NSArray *camerasArray = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if (userDefault == nil || data == nil || camerasArray == nil || camerasArray.count == 0) {
        return nil;
    }
    
    __block NSString *deviceID = nil;
    
    [camerasArray enumerateObjectsUsingBlock:^(SHShareCamera *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cameraUid isEqualToString:cameraUid]) {
            deviceID = obj.deviceID;
            *stop = YES;
        }
    }];
    
    return deviceID;
}

- (void)updateBadgeNumber {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSNumber *count = [defaults objectForKey:kRecvNotificationCount];
    NSInteger currentCount = 1;
    
    currentCount += count.integerValue;
    
    [defaults setObject:@(currentCount) forKey:kRecvNotificationCount];
}

- (NSString *)checkRecvTime:(NSString *)timeStr {
    //2019-06-06 10:25:55
    NSDateFormatter *formatter = [NSDateFormatter new];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSDate *recvDate = [formatter dateFromString:timeStr];
    NSInteger recvYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:recvDate];
    NSInteger currentYear = [[NSCalendar currentCalendar] component:NSCalendarUnitYear fromDate:[NSDate date]];
    
    if (recvYear != currentYear) {
        NSTimeInterval currentSecs = [[NSDate date] timeIntervalSinceNow] - 1;
        return [formatter stringFromDate:[NSDate dateWithTimeIntervalSinceNow:currentSecs]];
    }
   
    return timeStr;
}

@end

#endif

