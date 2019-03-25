//
//  SHTutkHttp.m
//  SmartHome
//
//  Created by yh.zhang on 2017/10/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHTutkHttp.h"
#import <UIKit/UIKit.h>
#import "HttpRequest.h"
#import "AppDelegate.h"

static NSString * const pushServer = @"http://push.iotcplatform.com/tpns?"; //@"http://push.kalay.net.cn/tpns?"
static NSString * const registerUrl = [pushServer stringByAppendingString:@"cmd=client"];
static NSString * const mapUrl = [pushServer stringByAppendingString:@"cmd=mapping"];
static NSString * const unmapUrl = [pushServer stringByAppendingString:@"cmd=rm_mapping"];
static NSString * const applicationId = @"com.icatchtek.smarthome";
static NSString * const keychain_key = @"push.udid";

@implementation SHTutkHttp

+ (void)registerDevice:(SHCamera *)camera {
#ifdef USE_SYNC_REQUEST_PUSH
    if ([self registerClient]) {
        [self mapping:camera];
    }
#else
    [self registerDevice:camera completionHandler:nil];
#endif
}

+ (BOOL)unregisterDevice:(NSString *)uid {
#ifdef USE_SYNC_REQUEST_PUSH
    return [self unmapping:uid];
#else
    [self unregisterDevice:uid completionHandler:nil];
    return YES;
#endif
}

+ (BOOL)registerClient {
    __block BOOL success = NO;

    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
        NSLog(@"This is device Token: %@", deviceToken);

    NSString *identifierNumber = [self getDeviceUUID];
        NSLog(@"手机序列号: %@",identifierNumber);
    
    int dev = 0;
#ifdef DEBUG
    dev = 1;
#endif
    
    NSString *url = [NSString stringWithFormat:@"%@&os=ios&token=%@&appid=%@&udid=%@&bgfetch=1&dev=%d", registerUrl,deviceToken,applicationId,identifierNumber, dev];
    
    if ([HttpRequest getSyncWithUrl:url]) {
        SHLogDebug(SHLogTagAPP, @"registerClient success.");
        success = YES;
    } else {
        SHLogError(SHLogTagAPP, @"registerClient failure.");
    }
    
    return success;
}

+ (void)mapping:(SHCamera *)camera {
#if DEBUG
    NSAssert(camera.cameraUid, @"uid must not be nil");
#else
    if (camera.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        return;
    }
#endif

    NSString *identifierNumber = [self getDeviceUUID];
    
    NSString *url = [NSString stringWithFormat:@"%@&appid=%@&uid=%@&udid=%@&lang=enUS&interval=1&os=ios&format=e21zZ30=", mapUrl,applicationId,camera.cameraUid,identifierNumber];
    
    if ([HttpRequest getSyncWithUrl:url]) {
        camera.mapToTutk = YES;
        
        SHLogDebug(SHLogTagAPP, @"mapping success.");
    } else {
        camera.mapToTutk = NO;

        SHLogError(SHLogTagAPP, @"mapping failure.");
    }
    
    [self updateCameraDataBase:camera];
}

+ (BOOL)unmapping:(NSString *)uid {
#if DEBUG
    NSAssert(uid, @"uid must not be nil");
#else
    if (uid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        return YES;
    }
#endif
    
    NSString *identifierNumber = [self getDeviceUUID];
    
    NSString *urlString = [NSString stringWithFormat:@"%@&appid=%@&udid=%@&os=ios&uid=%@", unmapUrl, applicationId, identifierNumber, uid];
    
    if ([HttpRequest getSyncWithUrl:urlString]) {
        SHLogDebug(SHLogTagAPP, @"unmapping success.");
        return YES;
    } else {
        SHLogError(SHLogTagAPP, @"unmapping failure.");
        return NO;
    }
}

+ (void)updateCameraDataBase:(SHCamera *)camera {
    // Save data to sqlite
    NSError *error = nil;
    if (![camera.managedObjectContext save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         */
        SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
        abort();
#endif
    } else {
        SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
    }
}

+ (NSString *)getDeviceUUID {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *identifierNumber = [defaults stringForKey:keychain_key];
    if (identifierNumber == nil) {
        identifierNumber = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
        NSString *dateString = [formatter stringFromDate:[NSDate date]];
        
        identifierNumber = [NSString stringWithFormat:@"%@+%@", identifierNumber, dateString];
        
        [defaults setObject:identifierNumber forKey:keychain_key];
    }
    
    return identifierNumber;
}

#pragma mark - New method
+ (void)registerDevice:(SHCamera *)camera completionHandler:(PushRequestCompletionBlock)completionHandler {
    [self registerClientWithCompletionHandler:^(BOOL isSuccess) {
        if (isSuccess) {
            [self mapping:camera completionHandler:completionHandler];
        } else {
            if (completionHandler) {
                completionHandler(isSuccess);
            }
        }
    }];
}

+ (void)unregisterDevice:(NSString *)uid completionHandler:(PushRequestCompletionBlock)completionHandler {
    NSString *cameraUid = [[NSString alloc] initWithString:uid];
    SHLogInfo(SHLogTagAPP, @"unregister device, uid is: %@", cameraUid);
    
    [self unmapping:cameraUid completionHandler:completionHandler];
}

+ (void)registerClientWithCompletionHandler:(PushRequestCompletionBlock)completionHandler {
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
    SHLogInfo(SHLogTagAPP, @"This is device Token: %@", deviceToken);
    
    NSString *identifierNumber = [self getDeviceUUID];
    SHLogInfo(SHLogTagAPP, @"手机序列号: %@",identifierNumber);
    
    if (deviceToken == nil || identifierNumber == nil) {
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
    
    int dev = 0;
#ifdef DEBUG
    dev = 1;
#endif
    
    NSString *url = [NSString stringWithFormat:@"%@&os=ios&token=%@&appid=%@&udid=%@&bgfetch=1&dev=%d", registerUrl,deviceToken,applicationId,identifierNumber, dev];
    
    [self requestWithURLString:url completionHandler:^(BOOL isSuccess) {
        SHLogInfo(SHLogTagAPP, @"registerClient is success: %d", isSuccess);
        
        if (completionHandler) {
            completionHandler(isSuccess);
        }
    }];
}

+ (void)mapping:(SHCamera *)camera completionHandler:(PushRequestCompletionBlock)completionHandler {
#if DEBUG
    NSAssert(camera.cameraUid, @"uid must not be nil");
#else
    if (camera.cameraUid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
#endif
    
    NSString *identifierNumber = [self getDeviceUUID];
    
    NSString *url = [NSString stringWithFormat:@"%@&appid=%@&uid=%@&udid=%@&lang=enUS&interval=1&os=ios&format=e21zZ30=", mapUrl,applicationId,camera.cameraUid,identifierNumber];
    
    [self requestWithURLString:url completionHandler:^(BOOL isSuccess) {
        SHLogInfo(SHLogTagAPP, @"mapping is success: %d, uid is: %@", isSuccess, camera.cameraUid);
        
        camera.mapToTutk = isSuccess;
        [self updateCameraDataBase:camera];
        
        if (completionHandler) {
            completionHandler(isSuccess);
        }
    }];
}

+ (void)unmapping:(NSString *)uid completionHandler:(PushRequestCompletionBlock)completionHandler {
#if DEBUG
    NSAssert(uid, @"uid must not be nil");
#else
    if (uid == nil) {
        SHLogError(SHLogTagAPP, @"camera uid is nil.");
        if (completionHandler) {
            completionHandler(YES);
        }
        
        return;
    }
#endif
    
    NSString *identifierNumber = [self getDeviceUUID];
    
    NSString *urlString = [NSString stringWithFormat:@"%@&appid=%@&udid=%@&os=ios&uid=%@", unmapUrl, applicationId, identifierNumber, uid];
    
    [self requestWithURLString:urlString completionHandler:^(BOOL isSuccess) {
        SHLogInfo(SHLogTagAPP, @"unmapping is success: %d, uid is: %@", isSuccess, uid);
        
        if (completionHandler) {
            completionHandler(isSuccess);
        }
    }];
}

#pragma mark - Request method
+ (void)requestWithURLString:(NSString *)urlString completionHandler:(PushRequestCompletionBlock)completionHandler {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    if (urlString == nil || url == nil) {
        SHLogError(SHLogTagAPP, @"urlString: %@, url: %@", urlString, url);
        
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
    
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
    if (request == nil) {
        SHLogError(SHLogTagAPP, @"request is nil.");
        
        if (completionHandler) {
            completionHandler(NO);
        }
        
        return;
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        SHLogInfo(SHLogTagAPP, "Request recv data: %@, error: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding], error);
        
        BOOL isSuccess = NO;
        NSHTTPURLResponse *response1 = (NSHTTPURLResponse*)response;
        if (error == nil && response1.statusCode == 200) {
            isSuccess = YES;
        }
        
        if (completionHandler) {
            completionHandler(isSuccess);
        }
    }] resume];
}

@end
