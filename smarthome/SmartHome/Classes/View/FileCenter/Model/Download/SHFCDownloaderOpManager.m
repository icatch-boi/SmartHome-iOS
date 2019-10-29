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
#import "filecache/FileCacheManager.h"
#import "XJLocalAssetHelper.h"

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
        [item.downloadArray addObject:fileInfo.copy];
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
        [item.finishedArray insertObject:fileInfo atIndex:0];
        
        self.downloadItems[fileInfo.deviceID] = item;
    } else {
        [item.finishedArray insertObject:fileInfo atIndex:0];
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
    if (self.operationCache[fileInfo.filePath]) {
        SHLogWarn(SHLogTagAPP, @"File '%@' is downloading.", fileInfo.fileName);
        return;
    }
    
    fileInfo.downloadState = SHDownloadStateDownloading;
    
    if ([self.delegate respondsToSelector:@selector(startDownloadWithFileInfo:)]) {
        [self.delegate startDownloadWithFileInfo:fileInfo];
    }
    
    WEAK_SELF(self);
    [self fileCenterDownloaderOpWithFileInfo:fileInfo finishedBlock:^{
        if (fileInfo.downloadState == SHDownloadStateCancelDownload) {
            SHLogWarn(SHLogTagAPP, @"File '%@' already cancel download.", fileInfo.fileName);
            return;
        }
        
        if (fileInfo.downloadState == SHDownloadStateDownloading) {
            SHLogError(SHLogTagAPP, @"Download error, corresponding file: '%@'", fileInfo.fileName);
            return;
        }
        
        [weakself downloadFinishedHandleWithFileInfo:fileInfo];
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
    if ([self checkLocalExist:fileInfo]) {
        fileInfo.downloadState = SHDownloadStateDownloadSuccess;
        [self addNewAssetToLocalAlbum:fileInfo];
        
        if (finishedBlock) {
            finishedBlock();
        }
        
        return;
    }
    
    WEAK_SELF(self);
    SHFCDownloaderOp *op = [SHFCDownloaderOp fileCenterDownloaderOpWithFileInfo:fileInfo finishedBlock:^{
        
        [weakself.operationCache removeObjectForKey:fileInfo.filePath];
        
        if ([weakself checkLocalExist:fileInfo]) {
            [weakself addNewAssetToLocalAlbum:fileInfo];
        }
        
        if (finishedBlock) {
            finishedBlock();
        }
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
    
    BOOL next = fileInfo.downloadState == SHDownloadStateDownloading;
    fileInfo.downloadState = SHDownloadStateCancelDownload;
    [self downloadFinishedHandleWithFileInfo:fileInfo];
    if (next) {
        [self startDownloadWithDeviceID:fileInfo.deviceID];
    }
}

- (void)downloadFinishedHandleWithFileInfo:(SHS3FileInfo *)fileInfo {
    [self addFinishedFile:fileInfo];
    [self removeDownloadFile:fileInfo];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadCompletionNotification object:nil];
}

- (SHDownloadItem *)downloadItemWithDeviceID:(NSString *)deviceID {
    return self.downloadItems[deviceID];
}

- (BOOL)checkLocalExist:(SHS3FileInfo *)fileInfo {
    string key = [self makeLocalKey:fileInfo].UTF8String;
    string cachePath;
    return FileCache::FileCacheManager::sharedFileCache()->diskFileDataExistsForKey(key, cachePath);
}

- (NSString *)makeLocalKey:(SHS3FileInfo *)fileInfo {
    return [NSString stringWithFormat:@"%@_%@", fileInfo.deviceID, fileInfo.fileName];
}

- (BOOL)addNewAssetToLocalAlbum:(SHS3FileInfo *)fileInfo {
    BOOL retVal = NO;
    NSURL *fileURL = nil;
    
    string key = [self makeLocalKey:fileInfo].UTF8String;
    string path = FileCache::FileCacheManager::sharedFileCache()->cachePathForKey(key);
    NSString *locatePath = [NSString stringWithFormat:@"%s", path.c_str()];
    if (locatePath) {
        fileURL = [NSURL fileURLWithPath:locatePath];
    } else {
        return retVal;
    }
    
    SHCameraObject *obj = [[SHCameraManager sharedCameraManger] getCameraObjectWithDeviceID:fileInfo.deviceID];

    if (locatePath && UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(locatePath)) {
        retVal = [[XJLocalAssetHelper sharedLocalAssetHelper] addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_VIDEO forKey:obj.camera.cameraUid];
    } else {
        SHLogError(SHLogTagAPP, @"The specified video can not be saved to user’s Camera Roll album");
    }
    
    return retVal;
}

@end
