//
//  SHSDK.h
//  SmartHome
//
//  Created by ZJ on 2017/4/17.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "SHSDKPrivate.h"
#import "SHAVData.h"
#import "SHObserver.h"
#import "SHFile.h"

#define VIDEO_BUFFER_SIZE 640 * 480 * 2
#define AUDIO_BUFFER_SIZE 1024 * 50

enum SHFileType {
    SHFileTypeImage  = ICH_FILE_TYPE_IMAGE,
    SHFileTypeVideo  = ICH_FILE_TYPE_VIDEO,
    SHFileTypeAudio  = ICH_FILE_TYPE_AUDIO,
    SHFileTypeText   = ICH_FILE_TYPE_TEXT,
    SHFileTypeAll    = ICH_FILE_TYPE_ALL,
    SHFileTypeUnknow = ICH_FILE_TYPE_UNKNOWN,
};

enum SHRetrunType {
    SHRetSuccess = ICH_SUCCEED,
    SHRetFail,
    SHRetNoSD,
    SHRetSDFUll,
};

@class SHCamera;
@class SHCameraObject;
@interface SHSDK : NSObject

@property (nonatomic, readonly) BOOL isSHSDKInitialized;
@property (nonatomic, readonly) dispatch_queue_t sdkQueue;
@property (nonatomic) BOOL isBusy;
//@property (nonatomic) NSMutableArray *downloadArray;
@property (nonatomic, readonly) Control *control;

#pragma mark - API adapter layer
// SDK
+ (instancetype)sharedSHSDK;
//- (instancetype)init __attribute__((unavailable("Disabled. Use + (instancetype)sharedSHSDK instead")));
- (int)initializeSHSDK:(NSString *)cameraUid devicePassword:(NSString *)devicePassword;
- (void)destroySHSDK;
- (void)disableTutk;
//- (void)enableLogSdkAtDiretctory:(NSString *)directoryName enable:(BOOL)enable;
- (NSString *)getTutkConnectMode;
- (void)openSaveVideo;
- (void)closeSaveVideo;
- (int)tryConnectCamera:(NSString *)cameraUid devicePassword:(NSString *)devicePassword;
- (void)destroyTryConnectResource;
+ (void)loadTutkLibrary;
+ (void)unloadTutkLibrary;
+ (void)checkDeviceStatusWithUID:(NSString *)uid;

// MEDIA
- (int)startMediaStreamWithEnableAudio:(BOOL)enableAudio camera:(SHCameraObject *)cameraObj;
- (BOOL)setVideoQuality:(ICatchVideoQuality)quality;
- (int)previewPlay;
- (BOOL)stopMediaStream;
- (int)previewStop;
- (BOOL)videoStreamEnabled;
- (BOOL)audioStreamEnabled;
- (ICatchVideoFormat)getVideoFormat;
- (ICatchAudioFormat)getAudioFormat;
- (SHAVData *)getVideoFrameData;
- (SHAVData *)getAudioFrameData;
- (BOOL)isMute;
- (BOOL)openAudio:(BOOL)isOpen;
- (BOOL)openAudioServer:(ICatchAudioFormat)audioFormat;
- (BOOL)closeAudioServer;
- (BOOL)startSendAudioFrame;
- (BOOL)stopSendAvdioFrame:(double)pts;
- (BOOL)readyCheck;
- (BOOL)sendAudioFrame:(ICatchFrameBuffer *)audioBuffer andDB:(double)db;
- (void)setAECEnabled:(BOOL)enabled;

// CONTROL
- (BOOL)setImagePath:(NSString *)path;
//- (BOOL)capturePhoto;
- (BOOL)capturePhoto:(NSString *)imageName;
- (int)startVideoRecord;
- (BOOL)stopVideoRecord;
- (void)addObserver:(SHObserver *)observer;
- (void)removeObserver:(SHObserver *)observer;
- (void)addObserver:(ICatchEventID)eventTypeId listener:(Listener *)listener isCustomize:(BOOL)isCustomize;
- (void)removeObserver:(ICatchEventID)eventTypeId listener:(Listener *)listener isCustomize:(BOOL)isCustomize;
- (BOOL)formatSD;
- (BOOL)factoryReset;
- (NSData *)requestThumbnail:(ICatchFile *)file andPropertyID:(int)propertyID;
- (BOOL)setupWiFiWithSSID:(NSString *)ssid password:(NSString *)password;

// Photo gallery
- (BOOL)deleteFile:(ICatchFile *)f;
- (NSString *)downloadFile:(ICatchFile )f path:(NSString *)path;
- (BOOL)cancelDownloadFile:(ICatchFile )f;
- (long)getDownloadedFileSize:(NSString *)filePath;
- (map<string, int>)getFilesStorageInfoWithStartDate:(NSString *)startDate andEndDate:(NSString *)endDate success:(BOOL *)isSuccess;
- (map<string, int>)getDailyFileCountWithStartDate:(NSString *)startDate andDaysNum:(int)daysNum;
- (vector<ICatchFile>)listFilesWhithDate:(string)date andStartIndex:(int)startIndex andNumber:(int)number;
- (BOOL)setFileTag:(ICatchFile *)f andIsFavorite:(BOOL)favorite;
- (BOOL)getFilesFilter:(ICatchFileFilter *)filter;
- (BOOL)setFilesFilter:(ICatchFileFilter *)filter;

// Video playback
- (double)play:(ICatchFile *)file;
- (BOOL)stop;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)seek:(double)point;
- (BOOL)videoPlaybackStreamEnabled;
- (BOOL)audioPlaybackStreamEnabled;
- (ICatchVideoFormat)getPlaybackVideoFormat;
- (ICatchAudioFormat)getPlaybackAudioFormat;
- (SHAVData *)getPlaybackVideoFrameData;
- (SHAVData *)getPlaybackAudioFrameData;
- (ICatchFrameBuffer *)getPlaybackAudioFrameData1;

//- (NSArray *)createMediaDirectoryWithPath:(NSString *)path;
//- (void)cleanUpDownloadDirectory;
- (int)resamplerWithInputBuffer:(char *)inputBuffer inputSize:(int)inputSize outputBuffer:(char *)outputBuffer outputSize:(int)outputSize;

- (BOOL)startPushMessageTest:(NSInteger)totalCount interval:(NSTimeInterval)interval;
- (BOOL)stopPushMessageTest;
- (BOOL)avSpeedTest:(int)timeInSecs avergeSpeed:(double *)averageSpeed;
- (BOOL)cancelAvSpeedTest;
- (BOOL)talkSpeedTest:(int)timeInSecs avergeSpeed:(double *)averageSpeed;
- (BOOL)cancelTalkSpeedTest;

@end
