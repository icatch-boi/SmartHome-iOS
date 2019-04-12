//
//  SHActionControl.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHActionControl.h"
#import "SHSDKEventListener.hpp"
#import "SHObserver.h"
#import "XJLocalAssetHelper.h"
#import <time.h>
@interface SHActionControl ()

@property (nonatomic) NSTimer *videoRecordTimer;
@property (nonatomic) long videoRecordElapsedTimeInSeconds;
@property (nonatomic) SHObserver *videoRecOffObserver;
@property (nonatomic) SHObserver *sdCardFullObserver;

@end

@implementation SHActionControl

- (void)startVideoRecWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)(int result))failedBlock noCardBlock:(void(^)())noCardBlock cardFullBlock:(void(^)())cardFullBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SHLogTRACE();
        int ret = [_shCamObj.sdk startVideoRecord];
        SHLogTRACE();
        
        if (ret == ICH_SUCCEED) {
            _isRecord = YES;
            _videoRecordElapsedTimeInSeconds = 0;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addObserver:self forKeyPath:@"videoRecordElapsedTimeInSeconds"
                          options:NSKeyValueObservingOptionNew context:nil];
                [self addVideoRecObserver];
                
                if (![_videoRecordTimer isValid]) {
                    self.videoRecordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                           target  :self
                                                                           selector:@selector(videoRecordingTimerCallback)
                                                                           userInfo:nil
                                                                           repeats :YES];
                }
            });
            
            if (successBlock) {
                successBlock();
            }
        } else {
            if (failedBlock) {
                failedBlock(ret);
            }
        }
    });
}

- (void)videoRecordingTimerCallback {
    ++self.videoRecordElapsedTimeInSeconds;

    if (_videoRecordingTimerBlock) {
        _videoRecordingTimerBlock();
    }
}

- (void)stopVideoRecWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SHLogTRACE();
        BOOL ret = [_shCamObj.sdk stopVideoRecord];
        SHLogTRACE();
        
        if (ret) {
            [_shCamObj.controler.propCtrl updateSDCardFreeSpaceSizeWithCamera:_shCamObj];
        }
        
        if (ret) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_videoRecordTimer isValid]) {
                    [_videoRecordTimer invalidate];
                    self.videoRecordElapsedTimeInSeconds = 0;
                }
                
                if (_isRecord) {
                    _isRecord = NO;
                    [self removeObserver:self forKeyPath:@"videoRecordElapsedTimeInSeconds"];
                    [self removeVideRecListener];
                }
            });
            
            if (successBlock) {
                successBlock();
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_videoRecordTimer isValid]) {
                    [_videoRecordTimer invalidate];
                    self.videoRecordElapsedTimeInSeconds = 0;
                }
                
                if (_isRecord) {
                    _isRecord = NO;
                    [self removeObserver:self forKeyPath:@"videoRecordElapsedTimeInSeconds"];
                    if (_shCamObj.isConnect) {
                        [self removeVideRecListener];
                    }
                }
            });
            
            if (failedBlock) {
                failedBlock();
            }
        }
    });
}

- (void)stillCaptureWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *photoPath = [NSString stringWithFormat:@"%@", NSTemporaryDirectory()];
        if ([_shCamObj.sdk setImagePath:photoPath]) {
            time_t t = time(0);
            struct tm *time1 = localtime(&t);
           
            NSString *imageName = [NSString stringWithFormat:@"%d%02d%02d_%02d%02d%02d.JPG",  time1->tm_year + 1900,
                    time1->tm_mon + 1, time1->tm_mday, time1->tm_hour, time1->tm_min,
                    time1->tm_sec];
            BOOL ret = [_shCamObj.sdk capturePhoto:imageName];
            
            if (ret) {
                if (successBlock) {
                    successBlock();
                }
                
                NSURL *fileURL = nil;
                if (imageName != nil) {
                    NSString *fullPath = [NSString stringWithFormat:@"%@%@",photoPath, imageName];
                    SHLogInfo(SHLogTagAPP, @"%@", fullPath);
                    fileURL = [NSURL fileURLWithPath:fullPath];
                    
                    [[XJLocalAssetHelper sharedLocalAssetHelper] addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_IMAGE forKey:_shCamObj.camera.cameraUid];
                }
            } else {
                if (failedBlock) {
                    failedBlock();
                }
            }
        }
    });
}

#pragma mark - Observer
- (void)addVideoRecObserver
{
    SHSDKEventListener *videoRecOffListener = new SHSDKEventListener(self, @selector(videoRecCallback:));
    self.videoRecOffObserver = [SHObserver cameraObserverWithListener:videoRecOffListener eventType:ICATCH_EVENT_VIDEO_OFF isCustomized:NO isGlobal:NO];
    
    [_shCamObj.sdk addObserver:self.videoRecOffObserver];
    
    SHSDKEventListener *sdCardFullListener = new SHSDKEventListener(self, @selector(videoRecCallback:));
    self.sdCardFullObserver = [SHObserver cameraObserverWithListener:sdCardFullListener eventType:ICATCH_EVENT_SDCARD_FULL isCustomized:NO isGlobal:NO];
    
    [_shCamObj.sdk addObserver:self.sdCardFullObserver];
}

- (void)videoRecCallback:(SHICatchEvent *)evt {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self removeVideRecListener];
        
        if (self.videoRecordBlock) {
            self.videoRecordBlock(evt);
        }
    });
}

- (void)removeVideRecListener
{
    if (self.videoRecOffObserver) {
        [_shCamObj.sdk removeObserver:self.videoRecOffObserver];
        
        if (self.videoRecOffObserver.listener) {
            delete self.videoRecOffObserver.listener;
            self.videoRecOffObserver.listener = NULL;
        }
        
        self.videoRecOffObserver = nil;
    }
    
    if (self.sdCardFullObserver) {
        [_shCamObj.sdk removeObserver:self.sdCardFullObserver];
        
        if (self.sdCardFullObserver.listener) {
            delete self.sdCardFullObserver.listener;
            self.sdCardFullObserver.listener = NULL;
        }
        
        self.sdCardFullObserver = nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"videoRecordElapsedTimeInSeconds"]) {
        if (self.updateVideoRecordTimerLabel) {
            self.updateVideoRecordTimerLabel(change);
        }
    }
}

@end
