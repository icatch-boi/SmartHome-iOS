// SHWiFiInfoHelper.m

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
 
 // Created by zj on 2019/7/17 7:42 PM.
    

#import "SHWiFiInfoHelper.h"

static NSString * const kLocalFileName = @"wifiInfo.plist";
static const NSUInteger kMaxSaveNum = 10;

@interface SHWiFiInfoHelper ()

@property (nonatomic, strong) NSMutableArray *wifiInfos;
@property (nonatomic, copy) NSString *filePath;

@end

@implementation SHWiFiInfoHelper

#pragma mark - Instance
+ (instancetype)sharedWiFiInfoHelper {
    static id instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nullptr] init];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedWiFiInfoHelper];
}

- (instancetype)init
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __block id self = [super init];
        if (self) {
            [self singletonInit];
        }
    });

    return self;
}

- (void)singletonInit {
    SHLogInfo(SHLogTagAPP, @"caller: %@; SingletonClass customic init", self);
    [self plistLoad];
}

#pragma mark - Output api
- (void)addWiFiInfo:(NSString *)ssid password:(NSString *)pwd {
    if (ssid.length <= 0 || pwd.length <= 0) {
        SHLogError(SHLogTagAPP, @"ssid or password is nil, ssid: %@, pwd: %@", ssid, pwd);
        return;
    }
    
    SHLogInfo(SHLogTagAPP, @"add WiFi info, ssid: %@, pwd: %@", ssid, pwd);
    while (self.wifiInfos.count >= kMaxSaveNum) {
        [self.wifiInfos removeObjectAtIndex:0];
    }
    
    NSDictionary *info = [self wifiInfoForSSID:ssid];
    if (info != nil) {
        NSString *key = [info.keyEnumerator nextObject];
        NSString *password = info[key];
        if ([password isEqualToString:pwd]) {
            SHLogInfo(SHLogTagAPP, @"Local existent wifi info, password same.");
            return;
        } else {
            SHLogInfo(SHLogTagAPP, @"Local existent wifi info, password don't same.");

            NSDictionary *temp = @{
                                   ssid: pwd,
                                   };
            NSUInteger idx = [self.wifiInfos indexOfObject:info];
            [self.wifiInfos replaceObjectAtIndex:idx withObject:temp];
        }
    } else {
        SHLogInfo(SHLogTagAPP, @"Local non-existent wifi info, need add.");
        
        NSDictionary *dict = @{
                               ssid: pwd,
                               };
        [self.wifiInfos addObject:dict];
    }
    
    [self plistSave];
}

- (NSString *)passwordForSSID:(NSString *)ssid {
    NSString *password = nil;
    
    NSDictionary *info = [self wifiInfoForSSID:ssid];
    if (info != nil) {
        NSString *key = [info.keyEnumerator nextObject];
        password = info[key];
    }
    
    return password;
}

#pragma mark - Private
- (NSDictionary *)wifiInfoForSSID:(NSString *)ssid {
    __block NSDictionary *info = nil;
    
    [self.wifiInfos enumerateObjectsUsingBlock:^(NSDictionary*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *key = [obj.keyEnumerator nextObject];
        if ([ssid isEqualToString:key]) {
            info = obj;
            *stop = YES;
        }
    }];
    
    return info;
}

- (void)plistLoad {
    NSArray *temp = [NSArray arrayWithContentsOfFile:self.filePath];
    SHLogInfo(SHLogTagAPP, @"Local save data: %@", temp);
    
    if (temp != nil) {
        self.wifiInfos = [NSMutableArray arrayWithArray:temp];
    } else {
        self.wifiInfos = [NSMutableArray arrayWithCapacity:10];
    }
}

- (void)plistSave {
    [self.wifiInfos.copy writeToFile:self.filePath atomically:YES];
    SHLogInfo(SHLogTagAPP, @"Save data to local success.");
}

- (NSString *)filePath {
    if (_filePath == nil) {
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        _filePath = [cachePath stringByAppendingPathComponent:kLocalFileName];
        SHLogInfo(SHLogTagAPP, @"Local file path: %@", _filePath);
    }
    
    return _filePath;
}

@end
