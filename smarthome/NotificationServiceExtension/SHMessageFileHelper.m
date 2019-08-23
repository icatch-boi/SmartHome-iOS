// SHMessageFileHelper.m

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
 
 // Created by zj on 2019/8/23 5:07 PM.
    

#import "SHMessageFileHelper.h"
#import "SHUtilsMacro.h"
#import "ZJDataCache.h"

typedef void(^RequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
static NSString * const DEVICE_MESSAGEFILE_PATH = @"v1/devices/messagefile";
static NSTimeInterval kTimeoutInterval = 15.0;

@implementation SHMessageFileHelper

- (void)getMessageFileWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(nullable MessageFileHelperCompletionBlock)completion {
    if (fileName.length == 0 || deviceID.length == 0) {
        SHLogWarn(SHLogTagAPP, @"file name or device id is nil.");
        
        if (completion) {
            completion(nil);
        }
        
        return;
    }
    
    [self getMessageFileInfoWithDeviceID:deviceID fileName:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
        SHLogInfo(SHLogTagAPP, @"getMessageFileWithDeviceID is success: %d", isSuccess);
        
        if (isSuccess == NO) {
            if (completion) {
                completion(nil);
            }
        } else {
            if (result == nil) {
                SHLogWarn(SHLogTagAPP, @"Result id is nil.");
                if (completion) {
                    completion(nil);
                }
                
                return;
            }
            
            NSDictionary *messageFile = result;
            if (![messageFile.allKeys containsObject:@"url"]) {
                SHLogWarn(SHLogTagAPP, @"Result not contains `url` key.");
                if (completion) {
                    completion(nil);
                }
                
                return;
            }
            
            [self downloadFileWithURLString:messageFile[@"url"] deviceID:deviceID fileName:fileName completion:^(BOOL isSuccess, id  _Nullable result) {
                SHLogInfo(SHLogTagAPP, @"downloadFileWithURLString is success: %d", isSuccess);
                
                NSString *localPath = nil;
                
                if (isSuccess == YES) {
                    NSString *key = [self makeCacheKeyWithDeviceID:deviceID fileName:fileName];
                    BOOL exist = [[ZJImageCache sharedImageCache] diskImageDataExistsWithKey:key];
                    if (exist) {
                        localPath = [[ZJImageCache sharedImageCache] cachePathForKey:key];
                    } else {
                        if (result != nil) {
                            localPath = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
                            if (![result writeToFile:localPath atomically:YES]) {
                                localPath = nil;
                            }
                        } else {
                            SHLogWarn(SHLogTagAPP, @"Result is nil.");
                        }
                    }
                }
                
                if (completion) {
                    completion(localPath);
                }
            }];
        }
    }];
}

- (void)getMessageFileInfoWithDeviceID:(NSString *)deviceID fileName:(NSString *)fileName completion:(RequestCompletionBlock)completion {
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
