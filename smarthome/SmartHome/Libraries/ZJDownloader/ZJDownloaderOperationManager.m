// ZJDownloaderOperationManager.m

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
 
 // Created by zj on 2019/8/29 3:45 PM.
    

#import "ZJDownloaderOperationManager.h"
#import "ZJDataCache.h"
#import "ZJDownloaderOperation.h"

@interface ZJDownloaderOperationManager ()

@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, strong) NSMutableDictionary *operationCache;

@end

@implementation ZJDownloaderOperationManager

+ (instancetype)sharedDownloader {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)downloadWithURLString:(NSString *)urlString cacheKey:(NSString * _Nullable)cacheKey finishedBlock:(DownloadFinishedBlock)finishedBlock {
    if (urlString.length == 0) {
        if (finishedBlock) {
            finishedBlock(urlString, nil);
        }
        
        return;
    }
    
    // Ops already exist
    if (self.operationCache[urlString]) {
        if (finishedBlock) {
            finishedBlock(urlString, nil);
        }
        
        return;
    }
    
    NSString *key = cacheKey ? cacheKey : urlString;
    UIImage *image = [[ZJImageCache sharedImageCache] imageFromCacheForKey:key];
    if (image != nil) {
        if (finishedBlock) {
            finishedBlock(urlString, image);
        }
        
        return;
    }
    
    // download ops
    ZJDownloaderOperation *op = [ZJDownloaderOperation downloaderOperationWithURLString:urlString cacheKey:key finishedBlock:^(NSString * _Nullable url, UIImage * _Nullable image) {
        if (finishedBlock) {
            finishedBlock(url, image);
        }
        
        [self.operationCache removeObjectForKey:urlString];
    }];
    
    [self.downloadQueue addOperation:op];
    self.operationCache[urlString] = op;
}

- (void)cancelOperation:(NSString *)urlString {
    if (urlString == nil) {
        return;
    }
    
    [self.operationCache[urlString] cancel];
    [self.operationCache removeObjectForKey:urlString];
}

#pragma mark - Init
- (NSOperationQueue *)downloadQueue {
    if (_downloadQueue == nil) {
        _downloadQueue = [NSOperationQueue new];
        _downloadQueue.maxConcurrentOperationCount = 6;
        _downloadQueue.name = @"com.icatchtek.ZJImageDownloader";
    }
    
    return _downloadQueue;
}

- (NSMutableDictionary *)operationCache {
    if (_operationCache == nil) {
        _operationCache = [NSMutableDictionary dictionaryWithCapacity:4];
    }
    
    return _operationCache;
}

@end
