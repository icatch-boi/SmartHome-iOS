// ZJDownloaderOperation.m

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
 
 // Created by zj on 2019/8/29 3:14 PM.
    

#import "ZJDownloaderOperation.h"
#import "ZJDataCache.h"

typedef void(^RequestCompletionBlock)(BOOL isSuccess, id _Nullable result);
//static NSTimeInterval kTimeoutInterval = 15.0;

@interface ZJDownloaderOperation ()

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *cacheKey;
@property (nonatomic, copy) DownloadFinishedBlock finishedBlock;

@end

@implementation ZJDownloaderOperation

+ (instancetype)downloaderOperationWithURLString:(NSString *)urlString cacheKey:(NSString *)cacheKey finishedBlock:(nullable DownloadFinishedBlock)finishedBlock {
    ZJDownloaderOperation *op = [[ZJDownloaderOperation alloc] init];
    
    op.urlString = urlString;
    op.cacheKey = cacheKey ? cacheKey : urlString;
    op.finishedBlock = finishedBlock;
    
    return op;
}

- (void)main {
    @autoreleasepool {
        NSURL *url = [[NSURL alloc] initWithString:_urlString];
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeoutInterval];
        
        if (_urlString == nil || url == nil || request == nil) {
            SHLogError(SHLogTagAPP, @"Download failed, urlString or url or request is nil.\n\t urlString: %@, url: %@, request: %@.", _urlString, url, request);
            if (self.finishedBlock) {
                self.finishedBlock(_urlString, nil);
            }
            
            return;
        }
        
        [self dataTaskWithRequest:request completion:^(BOOL isSuccess, id  _Nullable result) {
            SHLogInfo(SHLogTagAPP, @"download Message file is success: %d", isSuccess);
            
            UIImage *image = nil;
            
            if (isSuccess) {
                image = [[UIImage alloc] initWithData:result];
                
                if (image != nil) {
                    [[ZJImageCache sharedImageCache] storeImage:image forKey:_cacheKey completion:nil];
                }
            }
            
            if (self.isCancelled) {
                if (self.finishedBlock) {
                    self.finishedBlock(_urlString, nil);
                }
                
                return ;
            }
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                if (self.finishedBlock) {
                    self.finishedBlock(_urlString, image);
                }
            }];
        }];
    }
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
