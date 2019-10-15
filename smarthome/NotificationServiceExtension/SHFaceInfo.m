// SHFaceInfo.m

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
 
 // Created by zj on 2019/8/2 3:02 PM.
    

#import "SHFaceInfo.h"
#import "ZJDataCache.h"
#import "FaceCollectCommon.h"
#import "SHUtilsMacro.h"

typedef void (^ZJRequestCallBack)(_Nullable id result, id _Nullable error);
static NSTimeInterval TIME_OUT_INTERVAL = 15.0;

@interface SHFaceInfo ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *faceid;
@property (nonatomic, copy) NSNumber *expires;
@property (nonatomic, copy) NSNumber *facesnum;

@end

@implementation SHFaceInfo

+ (instancetype)faceInfoWithDict:(NSDictionary *)dict {
    return [[self alloc] initWithDict:dict];
}

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"faceid"]) {
        self.faceid = [value stringValue];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)getFaceImageWithCompletion:(FaceInfoGetFaceImageCompletionBlock)completion {
    NSString *accountID = [self getAccountID];
    
    if (_faceid != nil && accountID != nil) {
        NSString *key = FaceCollectImageKey(accountID, _faceid);
        NSString *localPath;

        if ([[ZJImageCache sharedImageCache] diskImageDataExistsWithKey:key]) {
            localPath = [[ZJImageCache sharedImageCache] cachePathForKey:key];
        }
        
        if (localPath) {
            if (completion) {
                completion(localPath);
            }
            
            return;
        }
    }
    
    [self downloadWithURLString:_url finished:^(id  _Nullable result, id _Nullable error) {
        if (error != nil) {
            NSLog(@"Get face image failed, error: %@", error);
            if (completion) {
                completion(nil);
            }
        } else {
            if (result != nil && [result isKindOfClass:[NSData class]]) {
                
                NSString *localPath;

                if (_faceid != nil && accountID != nil) {
                    NSString *key = FaceCollectImageKey(accountID, _faceid);
                    [[ZJImageCache sharedImageCache] storeImageDataToDisk:result forKey:key];
                    if ([[ZJImageCache sharedImageCache] diskImageDataExistsWithKey:key]) {
                        localPath = [[ZJImageCache sharedImageCache] cachePathForKey:key];
                    }
                } else {
                    localPath = [NSString stringWithFormat:@"%@/myAttachment.%@", NSTemporaryDirectory(), _url.pathExtension];
                    if (![result writeToFile:localPath atomically:YES]) {
                        localPath = nil;
                    }
                }
                
                if (completion) {
                    completion(localPath);
                }
            } else {
                if (completion) {
                    completion(nil);
                }
            }
        }
    }];
}

- (NSString *)getAccountID {
    NSUserDefaults *userDefault = [[NSUserDefaults alloc] initWithSuiteName:kAppGroupsName];
    NSDictionary *dict = [userDefault objectForKey:kUserAccountInfo];
    NSLog(@"dict: %@", dict);
    
    NSString *accountID = nil;
    if ([dict.allKeys containsObject:@"id"]) {
        accountID = dict[@"id"];
    }
    
    return accountID;
}

- (void)downloadWithURLString:(NSString *)urlString finished:(ZJRequestCallBack)finished {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIME_OUT_INTERVAL];
    
    if (urlString == nil || url == nil || request == nil) {
        NSLog(@"Download failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", urlString, url, request);
        if (finished) {
            NSDictionary *dict = @{
                                   @"error_description" : @"invalid parameter.",
                                   };
            finished(nil, dict);
        }
        
        return;
    }
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"连接错误: %@", error);
            if (finished) {
                finished(nil, error);
            }
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 304 || httpResponse.statusCode == 204) {
            // 解析数据
            //            id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            
            //            SHLogInfo(SHLogTagAPP, @"json: %@", json);
            if (finished) {
                finished(data, nil);
            }
        } else {
            if (httpResponse.statusCode == 401) {
                NSLog(@"Token invalid.");
            }
            
            NSLog(@"服务器内部错误");
            NSDictionary *dict = @{
                                   @"error_description": @"Unknown Error",
                                   };
            if (finished) {
                finished(nil, dict);
            }
        }
        
    }] resume];
}

@end
