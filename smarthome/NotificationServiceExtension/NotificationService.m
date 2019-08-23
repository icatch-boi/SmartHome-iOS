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
#import "ZJDataCache.h"

typedef void(^RequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
static NSString * const DEVICE_MESSAGEFILE_PATH = @"v1/devices/messagefile";
static NSTimeInterval kTimeoutInterval = 15.0;

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
        
        [self updateMessageCountWithCameraUID:userInfo[@"devID"]];
    } else {
        [self test];
//        self.contentHandler(self.bestAttemptContent);
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
    }
    
    if (str != nil) {
        self.bestAttemptContent.body = [NSString stringWithFormat:NSLocalizedString(@"kNotificationContentInfo", nil), devID, time, str];
    }
    
    [self updateMessageCountWithCameraUID:aps[@"devID"]];
    [self loacAttachmentWithMessage:aps completionHandle:^{
        self.contentHandler(self.bestAttemptContent);
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

- (void)updateBadgeNumber {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSNumber *count = [defaults objectForKey:kRecvNotificationCount];
    NSInteger currentCount = 1;
    
    currentCount += count.integerValue;
    
    [defaults setObject:@(currentCount) forKey:kRecvNotificationCount];
}

- (void)updateMessageCountWithCameraUID:(NSString *)uid {
    if (uid.length == 0) {
        NSLog(@"uid is nil.");
        return;
    }
    
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *local = [defaults objectForKey:kRecvNotificationCount];
    
    NSMutableDictionary *current;
    if (local == nil) {
        current = [[NSMutableDictionary alloc] init];
        [current setObject:@(1) forKey:uid];
    } else {
        current = [[NSMutableDictionary alloc] initWithDictionary:local];
        
        NSUInteger currentCount = 1;
        if ([current.allKeys containsObject:uid]) {
            currentCount += [current[uid] unsignedIntegerValue];
        }
        
        current[uid] = @(currentCount);
    }
    
    [defaults setObject:current.copy forKey:kRecvNotificationCount];
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

- (void)loacAttachmentWithMessage:(NSDictionary *)message completionHandle:(void(^)(void))completionHandler {
    if (message == nil) {
        SHLogWarn(SHLogTagAPP, @"Message is nil.");
        if (completionHandler) {
            completionHandler();
        }
        
        return;
    }
    
    if (![message.allKeys containsObject:@"timeInSecs"]) {
        SHLogWarn(SHLogTagAPP, @"Message not contains `timeInSecs` key.");
        if (completionHandler) {
            completionHandler();
        }
        
        return;
    }
    
    NSString *fileName = [self createFileNameWithTimeInSecs:message[@"timeInSecs"]];
    if (fileName.length == 0) {
        SHLogWarn(SHLogTagAPP, @"File name is nil.");
        if (completionHandler) {
            completionHandler();
        }
        
        return;
    }
    
    NSString *deviceID = [self getDeviceID:message[@"devID"]];
    if (deviceID.length == 0) {
        SHLogWarn(SHLogTagAPP, @"Device id is nil.");
        if (completionHandler) {
            completionHandler();
        }
        
        return;
    }
    
    [self getMessageFileWithDeviceID:deviceID fileName:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"getMessageFileWithDeviceID is success: %d", isSuccess);
        
        if (isSuccess == NO) {
            if (completionHandler) {
                completionHandler();
            }
        } else {
            if (result == nil) {
                SHLogWarn(SHLogTagAPP, @"Result id is nil.");
                if (completionHandler) {
                    completionHandler();
                }
                
                return;
            }
            
            NSDictionary *messageFile = result;
            if (![messageFile.allKeys containsObject:@"url"]) {
                SHLogWarn(SHLogTagAPP, @"Result not contains `url` key.");
                if (completionHandler) {
                    completionHandler();
                }
                
                return;
            }
            
            [self downloadFileWithURLString:messageFile[@"url"] deviceID:deviceID fileName:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
                SHLogInfo(SHLogTagAPP, @"downloadFileWithURLString is success: %d", isSuccess);
                
                if (isSuccess == NO) {
                    if (completionHandler) {
                        completionHandler();
                    }
                } else {
                    NSString *localPath;
                    
                    NSString *key = [self makeCacheKeyWithDeviceID:deviceID fileName:fileName];
                    BOOL exist = [[ZJImageCache sharedImageCache] diskImageDataExistsWithKey:key];
                    if (exist) {
                        localPath = [[ZJImageCache sharedImageCache] cachePathForKey:key];
                        [self configAttachment:localPath];
                    } else {
                        if (result != nil) {
                            localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                            if ([result writeToFile:localPath atomically:YES]) {
                                
                                [self configAttachment:localPath];
                            }
                        } else {
                            SHLogWarn(SHLogTagAPP, @"Result is nil.");
                        }
                    }
                    
                    if (completionHandler) {
                        completionHandler();
                    }
                }
            }];
        }
    }];
}

- (void)configAttachment:(NSString *)localPath {
    NSError *attachmentError = nil;
    UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"myAttachment" URL:[NSURL fileURLWithPath:localPath] options:nil error:&attachmentError];
    
    if (attachmentError) {
        SHLogError(SHLogTagAPP, @"%@", attachmentError.localizedDescription);
    } else {
        self.bestAttemptContent.attachments = @[attachment];
        self.bestAttemptContent.launchImageName = localPath.lastPathComponent;
    }
}

- (void)downloadFileWithURLString:(NSString *)urlString deviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(nullable RequestCompletionBlock)completion {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeoutInterval];
    
    if (urlString == nil || url == nil || request == nil) {
        SHLogError(SHLogTagAPP, @"Download failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description" : @"invalid parameter.",
                                   };
            completion(NO, dict);
        }
        
        return;
    }
    
    [self dataTaskWithRequest:request completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"download Message file is success: %d", isSuccess);
        
        UIImage *image;
        
        if (isSuccess) {
            image = [[UIImage alloc] initWithData:result];
            
            if (image != nil) {
                [[ZJImageCache sharedImageCache] storeImage:image forKey:[self makeCacheKeyWithDeviceID:deviceID fileName:fileName] completion:nil];
            }
        }
        
        if (completion) {
            completion(isSuccess, result);
        }
    }];
}

- (void)getMessageFileWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(RequestCompletionBlock)completion {
    if (fileName.length == 0 || deviceID.length == 0) {
        SHLogWarn(SHLogTagAPP, @"file name or device id is nil.");
        
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description" : @"invalid parameter.",
                                   };
            completion(NO, dict);
        }
        
        return;
    }
    
    NSString *token = [self makeAccessToken];
    if (token == nil) {
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description" : @"invalid parameter.",
                                   };
            completion(NO, dict);
        }
        
        return;
    }
    
    NSURL *url = [NSURL URLWithString:[kServerBaseURL stringByAppendingString:[NSString stringWithFormat:@"%@?id=%@&filename=%@", DEVICE_MESSAGEFILE_PATH, deviceID, fileName]]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url cachePolicy:0 timeoutInterval:kTimeoutInterval];
    request.HTTPMethod = @"get";
    [request setValue:token forHTTPHeaderField:@"Authorization"];
    
    [self dataTaskWithRequest:request.copy completion:completion];
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

- (NSString *)createFileNameWithTimeInSecs:(NSNumber *)timeInSecs {
    NSString *fileName;
    if (timeInSecs != nil) {
        fileName = [NSString stringWithFormat:@"%@.jpg", timeInSecs];
    }
    
    return fileName;
}

- (NSString *)makeCacheKeyWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName {
    return (deviceID && fileName) ? [NSString stringWithFormat:@"%@_%@", deviceID, fileName] : nil;
}

- (NSString *)makeAccessToken {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *dict = [userDefault objectForKey:kUserAccount];
    NSLog(@"dict: %@", dict);
    
    if (![dict.allKeys containsObject:@"access_token"]) {
        return nil;
    }
    
    return [@"Bearer " stringByAppendingString:dict[@"access_token"]];
}

#pragma mark - Data Task Handle
- (void)dataTaskWithRequest:(NSURLRequest *)request completion:(RequestCompletionBlock)completion {
    if (request == nil) {
        SHLogError(SHLogTagAPP, @"dataTaskWithRequest failed, `request` is nil.");
        
        if (completion) {
            NSDictionary *dict = @{
                                   @"error_description" : @"invalid parameter.",
                                   };
            
            completion(NO, dict);
        }
        
        return;
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            SHLogError(SHLogTagAPP, @"连接错误: %@", error);
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
            NSError *error;
            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (error != nil) {
                SHLogError(SHLogTagAPP, @"JSON parse failed, error: %@", error);
                json = data;
            }
            
            if (completion) {
                completion(YES, json);
            }
        } else {
            if (httpResponse.statusCode == 401) {
                SHLogError(SHLogTagAPP, @"Token invalid.");
            }
            
            SHLogError(SHLogTagAPP, @"服务器内部错误");
            NSDictionary *dict = @{
                                   @"error_description": @"Unknown Error",
                                   };
            if (completion) {
                completion(NO, dict);
            }
        }
        
    }] resume];
}

@end

#endif

