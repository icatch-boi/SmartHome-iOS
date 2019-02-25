//
//  SHDownloader.m
//  SmartHome
//
//  Created by ZJ on 2017/6/9.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHDownloader.h"
#import "SHSDKEventListener.hpp"
#import "SHObserver.h"
#import "SHDownloadManager.h"
#import "XJLocalAssetHelper.h"

@interface SHDownloader ()

@property (nonatomic) SHCameraObject *shCamObj;

@property(nonatomic) BOOL downloadFileProcessing;
@property(nonatomic) NSUInteger downloadedPercent;
@property(nonatomic) dispatch_queue_t downloadQueue;
@property(nonatomic) dispatch_queue_t downloadPercentQueue;

@property (nonatomic, strong) SHFile *file;
@property (nonatomic, strong) SHObserver *startDownloadObserver;
@property (nonatomic, strong) SHObserver *endDownloadObserver;

@end

@implementation SHDownloader

- (dispatch_queue_t)downloadQueue {
    if (!_downloadQueue) {
        _downloadQueue = dispatch_queue_create("SmartHoem.GCD.Queue.Playback.Download", 0);
    }
    
    return _downloadQueue;
}

- (dispatch_queue_t)downloadPercentQueue {
    if (!_downloadPercentQueue) {
        _downloadPercentQueue = dispatch_queue_create("SmartHome.GCD.Queue.Playback.DownloadPercent", 0);
    }
    
    return _downloadPercentQueue;
}

- (instancetype)initWithCameraObject:(SHCameraObject *)camObj {
    if (self = [super init]) {
        self.shCamObj = camObj;
    }
    
    return self;
}

- (void)cancelDownloadFile:(SHFile *)file successBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
	SHLogTRACE();
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([self.shCamObj.sdk cancelDownloadFile:file.f]) {
            if (successBlock) {
                self.downloadFileProcessing = NO;

                successBlock();
            } else {
                if (failedBlock) {
                    failedBlock();
                }
            }
        }
    });
}

- (Boolean)cancelDownloadFile:(SHFile *)file  {
	SHLogTRACE();
	if ([self.shCamObj.sdk cancelDownloadFile:file.f]) {
		self.downloadFileProcessing = NO;
		return YES;
	} else {
		return NO;
	}
}


- (void)downloadFile:(SHFile *)file
{
	SHLogTRACE();
	
	self.file = file;
	
	[self addObserver:self forKeyPath:@"downloadedPercent" options:NSKeyValueObservingOptionNew context:nil];
	
	dispatch_async(self.downloadQueue, ^{
		[self addDownloadObserver];
		
		self.downloadFileProcessing = YES;
		self.downloadedPercent = 0;//Before the download clear downloadedPercent and increase downloadedFileNumber.
		[self requestDownloadPercent:file.f];
		if (![self.shCamObj.sdk downloadFile:file.f path:_shCamObj.camera.cameraUid]) {
			[self.delegate onDownloadComplete:file retvalue:false];
			self.shCamObj.cameraProperty.downloadFailedNum ++;
		    [self removeDownloadObserver];
				
			dispatch_async(dispatch_get_main_queue(), ^{
                @try {
                    [self removeObserver:self forKeyPath:@"downloadedPercent"];
                } @catch(NSException *exception) {
                    SHLogError(SHLogTagAPP, @"remove observer happen exception: %@", exception);
                }
			});
		}else{

        }
		
		self.downloadFileProcessing = NO;
	});
}


- (void)requestDownloadPercent:(ICatchFile)file
{
    ICatchFile f = file;
    NSString *locatePath = nil;
    NSString *fileName = [NSString stringWithUTF8String:f.getFileName().c_str()];
    unsigned long long fileSize = f.getFileSize();
    
    locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    SHLogInfo(SHLogTagAPP, @"locatePath: %@, %llu", locatePath, fileSize);
    
    UIApplication  *app = [UIApplication sharedApplication];
    __block  UIBackgroundTaskIdentifier downloadTask;
    __block UIApplicationState currentState;

    dispatch_async(self.downloadPercentQueue, ^{
        do {
            @autoreleasepool {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    currentState = app.applicationState;
                });
                if (currentState == UIApplicationStateBackground) {
                    downloadTask = [app beginBackgroundTaskWithExpirationHandler: ^{
                        float progress = [self.shCamObj.sdk getDownloadedFileSize:locatePath] * 1.0 / fileSize;
						if(progress == -1){//meet error ,so close this thread!
							self.downloadFileProcessing = NO;
						}
                        self.downloadedPercent = progress * 100;
                        SHLogInfo(SHLogTagAPP, @"percent: %lu", (unsigned long)self.downloadedPercent);
                        
                        [NSThread sleepForTimeInterval:0.25];
                        
                        [[UIApplication sharedApplication] endBackgroundTask:downloadTask];
                        downloadTask = UIBackgroundTaskInvalid;
                    }];
                } else {
                    float progress = [self.shCamObj.sdk getDownloadedFileSize:locatePath] * 1.0 / fileSize;
                    self.downloadedPercent = progress * 100;
                    
                    [NSThread sleepForTimeInterval:0.25];
                }
            }
        } while (self.downloadFileProcessing);
        
    });
}

- (void)addDownloadObserver {
	SHSDKEventListener *startDownloadlListener = new SHSDKEventListener(self, @selector(startDownload));
    self.startDownloadObserver = [SHObserver cameraObserverWithListener:startDownloadlListener eventType:ICATCH_EVENT_DOWNLOAD_FILE_BEGIN isCustomized:NO isGlobal:NO];
    
    [_shCamObj.sdk addObserver:self.startDownloadObserver];
    
    SHSDKEventListener *endDownloadlListener = new SHSDKEventListener(self, @selector(endtDownload:));
    self.endDownloadObserver = [SHObserver cameraObserverWithListener:endDownloadlListener eventType:ICATCH_EVENT_DOWNLOAD_FILE_END isCustomized:NO isGlobal:NO];
    
    [_shCamObj.sdk addObserver:self.endDownloadObserver];
}

- (void)removeDownloadObserver {
    if (self.startDownloadObserver) {
        [_shCamObj.sdk removeObserver:self.startDownloadObserver];
        
        if (self.startDownloadObserver.listener) {
            delete self.startDownloadObserver.listener;
            self.startDownloadObserver.listener = NULL;
        }
        
        self.startDownloadObserver = nil;
    }
    
    if (self.endDownloadObserver) {
        [_shCamObj.sdk removeObserver:self.endDownloadObserver];
        
        if (self.endDownloadObserver.listener) {
            delete self.endDownloadObserver.listener;
            self.endDownloadObserver.listener = NULL;
        }
        
        self.endDownloadObserver = nil;
    }
}

- (void)startDownload {
    SHLogTRACE();
    
    self.downloadFileProcessing = YES;
    [self requestDownloadPercent:_file.f];
}

- (void)endtDownload:(SHICatchEvent *)sender {
    SHLogTRACE();
    
    int value = sender.intValue1;
    NSString *description = NSLocalizedString(@"kFileDownloadSuccess", nil);

    switch (value) {
        case 0:
            SHLogInfo(SHLogTagAPP, @"下载成功");
			if ([self.delegate respondsToSelector:@selector(onDownloadComplete:retvalue:)]){
				SHLogInfo(SHLogTagAPP, @"notify onDownloadComplete!");
                [self.delegate onDownloadComplete:self.file retvalue:YES];
			}
            if ([self.delegate respondsToSelector:@selector(onProgressUpdate:progress:)]) {
                [self.delegate onProgressUpdate:self.file progress:100];
            }

            self.shCamObj.cameraProperty.downloadSuccessedNum ++;
            
            [[XJLocalAssetHelper sharedLocalAssetHelper] addNewAssetToLocalAlbum:self.file.f forKey:self.shCamObj.camera.cameraUid];
            description = NSLocalizedString(@"kFileDownloadSuccess", nil);
            break;
         
        case -1:
            SHLogError(SHLogTagAPP, @"下载失败 - fw出错");
            if ([self.delegate respondsToSelector:@selector(onDownloadComplete:retvalue:)]) {
                SHLogInfo(SHLogTagAPP, @"notify onDownloadComplete, fw happen error.");
                [self.delegate onDownloadComplete:self.file retvalue:NO];
            }
            description = NSLocalizedString(@"kFileDownloadFailed", nil);
            break;
            
        case -2:
            SHLogWarn(SHLogTagAPP, @"下载失败 - 用户cancel");
            if ([self.delegate respondsToSelector:@selector(onCancelDownloadComplete:retvalue:)]) {
                [self.delegate onCancelDownloadComplete:self.file retvalue:YES];
            }
            description = NSLocalizedString(@"kFileDownloadCancel", nil);
            break;
            
        default:
            break;
    }
    
    NSString *fileName = [NSString stringWithFormat:@"%s", self.file.f.getFileName().c_str()];
    if (fileName == nil) {
        fileName = @"file";
    }
    SHLogInfo(SHLogTagAPP, @"current file is: %@", fileName);
    
    if (!_shCamObj.isEnterBackground) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kSingleDownloadCompleteNotification object:nil userInfo:@{@"cameraName": _shCamObj.camera.cameraName,@"file": /*_file*/fileName, @"Description": description}];
    }

    self.downloadFileProcessing = NO;
    [self removeDownloadObserver];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [self removeObserver:self forKeyPath:@"downloadedPercent"];
        } @catch (NSException *exception) {
            SHLogError(SHLogTagAPP, @"remove observer happen exception: %@", exception);
        }
    });
}

#pragma mark - Observer
- (void)observeValueForKeyPath:(NSString *)keyPath
        ofObject              :(id)object
        change                :(NSDictionary *)change
        context               :(void *)context
{
    if ([keyPath isEqualToString:@"downloadedPercent"]) {
        if ([self.delegate respondsToSelector:@selector(onProgressUpdate:progress:)]) {
            [self.delegate onProgressUpdate:self.file progress:(int)self.downloadedPercent];
        }
    }
}

@end
