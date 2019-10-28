// SHFCDownloaderOpManager.m

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
 
 // Created by zj on 2019/10/25 7:27 PM.
    

#import "SHFCDownloaderOpManager.h"
#import "SHFCDownloaderOp.h"

@interface SHFCDownloaderOpManager ()

@property (nonatomic, strong) NSMutableDictionary *downloadItems;
@property (nonatomic, strong) NSMutableDictionary *operationCache;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation SHFCDownloaderOpManager

+ (instancetype)sharedDownloader {
    static id instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:nullptr] init];
    });
    
    return instance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedDownloader];
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
    self.downloadItems = [NSMutableDictionary dictionary];
    self.operationCache = [NSMutableDictionary dictionary];
    self.downloadQueue = [[NSOperationQueue alloc] init];
    self.downloadQueue.maxConcurrentOperationCount = 6;
    self.downloadQueue.name = @"com.icatchtek.FileCenterDownloader";
}

- (void)addDownloadFile:(SHS3FileInfo *)fileInfo {
    SHDownloadItem *item = self.downloadItems[fileInfo.deviceID];
    if (item == nil) {
        item = [[SHDownloadItem alloc] init];
        [item.downloadArray addObject:fileInfo.copy];
        
        self.downloadItems[fileInfo.deviceID] = item;
    } else {
        if (![item.downloadArray containsObject:fileInfo]) {
            [item.downloadArray addObject:fileInfo.copy];
        }
    }
}

- (void)removeDownloadFile:(SHS3FileInfo *)fileInfo {
    SHDownloadItem *item = self.downloadItems[fileInfo.deviceID];
    if (item) {
        [item.downloadArray removeObject:fileInfo];
    }
}

- (void)addFinishedFile:(SHS3FileInfo *)fileInfo {
    SHDownloadItem *item = self.downloadItems[fileInfo.deviceID];
    if (item == nil) {
        item = [[SHDownloadItem alloc] init];
        [item.finishedArray addObject:fileInfo];
        
        self.downloadItems[fileInfo.deviceID] = item;
    } else {
        [item.finishedArray addObject:fileInfo];
    }
}

- (void)startDownloadWithDeviceID:(NSString *)deviceID {
    if (deviceID == nil) {
        return;
    }
    
    SHDownloadItem *item = self.downloadItems[deviceID];
    if (item == nil) {
        return;
    }
    
    NSArray *downloadArray = item.downloadArray;
    if (downloadArray.count == 0) {
        return;
    }
    
    SHS3FileInfo *fileInfo = item.downloadArray.firstObject;
    fileInfo.downloadState = SHDownloadStateDownloading;
    
    if ([self.delegate respondsToSelector:@selector(startDownloadWithFileInfo:)]) {
        [self.delegate startDownloadWithFileInfo:fileInfo];
    }
    
    WEAK_SELF(self);
    [self fileCenterDownloaderOpWithFileInfo:fileInfo finishedBlock:^{
        fileInfo.downloadState = SHDownloadStateFinished;
        
        [weakself addFinishedFile:fileInfo];
        [weakself removeDownloadFile:fileInfo];
        
//        if ([weakself.delegate respondsToSelector:@selector(downloadCompletionWithFileInfo:)]) {
//            [weakself.delegate downloadCompletionWithFileInfo:fileInfo];
//        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadCompletionNotification object:nil];
        
        [weakself startDownloadWithDeviceID:deviceID];
    }];
}

- (void)fileCenterDownloaderOpWithFileInfo:(SHS3FileInfo *)fileInfo finishedBlock:(nullable DownloadFinishedBlock)finishedBlock {
    if (fileInfo == nil) {
        if (finishedBlock) {
            finishedBlock();
        }
        
        return;
    }
    
    if (self.operationCache[fileInfo.filePath]) {
        if (finishedBlock) {
            finishedBlock();
        }
        
        return;
    }
    
    // check disk
    // ...
    
    WEAK_SELF(self);
    SHFCDownloaderOp *op = [SHFCDownloaderOp fileCenterDownloaderOpWithFileInfo:fileInfo finishedBlock:^{
        if (finishedBlock) {
            finishedBlock();
        }
        
        [weakself.operationCache removeObjectForKey:fileInfo.filePath];
    }];
    
    [self.downloadQueue addOperation:op];
    self.operationCache[fileInfo.filePath] = op;
}

- (void)cancelDownload:(SHS3FileInfo *)fileInfo {
    if (fileInfo == nil) {
        return;
    }
    
    [(SHFCDownloaderOp *)self.operationCache[fileInfo.filePath] cancel];
    [self.operationCache removeObjectForKey:fileInfo.filePath];
}

- (SHDownloadItem *)downloadItemWithDeviceID:(NSString *)deviceID {
    return self.downloadItems[deviceID];
}

@end
