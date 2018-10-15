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
#import "LRKeychain.h"

static NSString * const pushServer = @"http://push.iotcplatform.com/tpns?"; //@"http://push.kalay.net.cn/tpns?"
static NSString * const registerUrl = [pushServer stringByAppendingString:@"cmd=client"];
static NSString * const mapUrl = [pushServer stringByAppendingString:@"cmd=mapping"];
static NSString * const unmapUrl = [pushServer stringByAppendingString:@"cmd=rm_mapping"];
static NSString * const applicationId = @"com.icatchtek.smarthome"; //@"com.xj.app.doorbell";
static NSString * const keychain_key = @"push.udid";

@implementation SHTutkHttp

+ (void)registerDevice:(SHCamera *)camera {
    if ([self registerClient]) {
        [self mapping:camera];
    }
}

+ (BOOL)unregisterDevice:(NSString *)uid {
    return [self unmapping:uid];
}

+ (BOOL)registerClient {
    __block BOOL success = NO;
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        AppDelegate *delegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
//        NSString *deviceToken = delegate.deviceToken;
    NSString *deviceToken = [[NSUserDefaults standardUserDefaults] objectForKey:kDeviceToken];
        NSLog(@"This is device Token: %@", deviceToken);

//        NSString *identifierNumber = [LRKeychain getKeychainDataForKey:keychain_key];
//        if (identifierNumber == nil) {
//            identifierNumber = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//            [LRKeychain addKeychainData:identifierNumber forKey:keychain_key];
//        }
    NSString *identifierNumber = [self getDeviceUUID];
        NSLog(@"手机序列号: %@",identifierNumber);
    
    int dev = 0;
#ifdef DEBUG
    dev = 1;
#endif
    
        NSString *url = [NSString stringWithFormat:@"%@&os=ios&token=%@&appid=%@&udid=%@&bgfetch=1&dev=%d", registerUrl,deviceToken,applicationId,identifierNumber, dev];
//    NSString *url = [NSString stringWithFormat:@"%@&os=ios&token=%@&appid=%@&udid=%@&bgfetch=1", registerUrl,deviceToken,applicationId,identifierNumber];
        
        if ([HttpRequest getSyncWithUrl:url]) {
            SHLogDebug(SHLogTagAPP, @"registerClient success.");
            success = YES;
        } else {
            SHLogError(SHLogTagAPP, @"registerClient failure.");
        }
//    });
    
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

//    dispatch_async(dispatch_get_main_queue(), ^{
//        NSString *identifierNumber = [LRKeychain getKeychainDataForKey:keychain_key];
//        if (identifierNumber == nil) {
//            identifierNumber = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//            [LRKeychain addKeychainData:identifierNumber forKey:keychain_key];
//        }
        NSString *identifierNumber = [self getDeviceUUID];
        
        NSString *url = [NSString stringWithFormat:@"%@&appid=%@&uid=%@&udid=%@&lang=enUS&interval=0&os=ios&format=e21zZ30=", mapUrl,applicationId,camera.cameraUid,identifierNumber];
        
        if ([HttpRequest getSyncWithUrl:url]) {
            camera.mapToTutk = YES;
            
            SHLogDebug(SHLogTagAPP, @"mapping success.");
        } else {
            camera.mapToTutk = NO;

            SHLogError(SHLogTagAPP, @"mapping failure.");
        }
        
        [self updateCameraDataBase:camera];
//    });
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
    
    // push.iotcplatform.com:7379/fb/tpns?cmd=rm_mapping&appid=com.icatchtek.smarthome&udid=MAC&os=jiguang&uid=UID
//    NSString *identifierNumber = [LRKeychain getKeychainDataForKey:keychain_key];
//    if (identifierNumber == nil) {
//        identifierNumber = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
//        [LRKeychain addKeychainData:identifierNumber forKey:keychain_key];
//    }
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
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
//    });
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

@end
