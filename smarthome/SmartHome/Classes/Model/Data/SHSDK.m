//
//  SHSDK.m
//  SmartHome
//
//  Created by ZJ on 2017/4/17.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHSDK.h"
#include "SHH264StreamParameter.hpp"
#import <Photos/Photos.h>
#import "XJLocalAssetHelper.h"
#import "SHNetworkManagerHeader.h"

@interface SHSDK ()

@property (nonatomic) Session *session;
@property (nonatomic) Preview *preview;
@property (nonatomic) Control *control;
@property (nonatomic) Playback *playback;
@property (nonatomic) VideoPlayback *vplayback;
@property (nonatomic) AudioServer *aserver;
//@property (nonatomic) Resampler *resampler;
@property (nonatomic) shared_ptr<Resampler> resampler;
@property (nonatomic) EnvironmentCheck *checkInstance;

@property (nonatomic) ICatchFrameBuffer *videoFrameBuffer;
@property (nonatomic) ICatchFrameBuffer *audioFrameBuffer;

@property (nonatomic) NSMutableData *videoData;
@property (nonatomic) NSMutableData *audioData;

@property (nonatomic) NSRange videoRange;
@property (nonatomic) NSRange audioRange;

@property (nonatomic) BOOL isStopped;
@property (nonatomic, readwrite) BOOL isSHSDKInitialized;
@property (nonatomic, readwrite) dispatch_queue_t sdkQueue;

@property (nonatomic) FILE *file;

@end

@implementation SHSDK

#pragma mark - 
- (ICatchFrameBuffer *)videoFrameBuffer {
    if (!_videoFrameBuffer) {
        _videoFrameBuffer = new ICatchFrameBuffer(VIDEO_BUFFER_SIZE);
    }
    
    return _videoFrameBuffer;
}

- (ICatchFrameBuffer *)audioFrameBuffer {
    if (!_audioFrameBuffer) {
        _audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
    }
    
    return _audioFrameBuffer;
}

- (NSMutableData *)videoData {
    if (!_videoData) {
        _videoData = [[NSMutableData alloc] initWithCapacity:VIDEO_BUFFER_SIZE];
    }
    
    return _videoData;
}

- (NSMutableData *)audioData {
    if (!_audioData) {
        _audioData = [[NSMutableData alloc] initWithCapacity:AUDIO_BUFFER_SIZE];
    }
    
    return _audioData;
}

//- (smarthome::Resampler *)resampler {
//    if (_resampler == nil) {
//        _resampler = new Resampler();
//		NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
//		int audioRate = [defaultSettings integerForKey:@"PreferenceSpecifier:audioRate"];
//        int ret = _resampler->init(1, 48000, audioRate);
//        SHLogInfo(SHLogTagAPP, @"Resampler init, ret: %d", ret);
//    }
//
//    return _resampler;
//}

- (void)initResampler {
    self.resampler = make_shared<Resampler>();
    
    if (self.resampler != nullptr) {
        NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
        int audioRate = (int)[defaultSettings integerForKey:@"PreferenceSpecifier:audioRate"];
        int ret = _resampler->init(1, 48000, audioRate);
        SHLogInfo(SHLogTagAPP, @"Resampler init, ret: %d", ret);
        
        if (ret != ICH_SUCCEED) {
            _resampler = nullptr;
        }
    }
}

- (int)resamplerWithInputBuffer:(char *)inputBuffer inputSize:(int)inputSize outputBuffer:(char *)outputBuffer outputSize:(int)outputSize {
    if (self.resampler == nil) {
        SHLogError(SHLogTagAPP, @"resampler is nil");
        return -1;
    }
    
    int retVal = self.resampler->resampler(inputBuffer , inputSize, outputBuffer, outputSize);
//    SHLogDebug(SHLogTagAPP, @"resampler, retVal: %d", retVal);

    return retVal;
}

#pragma mark - SHSDK status
+ (instancetype)sharedSHSDK {
    static SHSDK *instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.sdkQueue = dispatch_queue_create("SmartHome.GCD.Queue.SHSDKQ.Singleton", DISPATCH_QUEUE_SERIAL);
    });
    
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.sdkQueue = dispatch_queue_create("SmartHome.GCD.Queue.SHSDKQ", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

+ (void)loadTutkLibrary {
    Session::loadTutkLibrary();
}

+ (void)unloadTutkLibrary {
    Session::unloadTutkLibrary();
}

+ (void)checkDeviceStatusWithUID:(NSString *)uid {
    bool enableBackgroundWakeup = false;
    
    do {
        NSDictionary *info = [SHNetworkManager sharedNetworkManager].userAccount.userExtensionsInfo;
        if (info == nil) {
            return;
        }
        
        if (![info.allKeys containsObject:@"bgWakeup"]) {
            return;
        }
        
        enableBackgroundWakeup = [info[@"bgWakeup"] intValue];
    } while (0);

    Session::checkDeviceStatus(uid.UTF8String, enableBackgroundWakeup);
}

- (int)initializeSHSDK:(NSString *)cameraUid devicePassword:(NSString *)devicePassword {
	//convert to uppercase
	NSString *upperUid = [cameraUid uppercaseStringWithLocale:[NSLocale currentLocale]];
    int retVal = ICH_SUCCEED;

    do {
        SHLogInfo(SHLogTagAPP, @"---START INITIALIZE SHSDK(Data Access Layer)---");
        if (self.isSHSDKInitialized) {
            SHLogInfo(SHLogTagAPP, @"SDK has been initialized.");
            break;
        }
        

        self.session = new Session();
        if (self.session == NULL) {
            SHLogError(SHLogTagSDK, @"Create session failed.");
            retVal = ICH_NULL;
            break;
        }
        
        SHLogInfo(SHLogTagSDK, @"start enableTutk.");
        string password = devicePassword ? devicePassword.UTF8String : "1234";
        if ((retVal = self.session->enableTutk(upperUid.UTF8String, password)) != ICH_SUCCEED) {
            SHLogInfo(SHLogTagSDK, @"enableTutk failed.");
            break;
        }
        
        SHLogInfo(SHLogTagSDK, @"start prepareSession.");
        
        if (self.session->prepareSession() != ICH_SUCCEED) {
            SHLogInfo(SHLogTagSDK, @"prepareSession failed.");
            self.session->disableTutk();
            retVal = ICH_NULL;
            break;
        }
        
        SHLogInfo(SHLogTagSDK, @"prepareSession done.");
        
        NSString *mode = [[[SHCamStaticData instance] tutkModeDict] objectForKey:@(self.session->getTutkConnectMode())];
        SHLogInfo(SHLogTagSDK, @"TutkConnectMode: %@", mode);
        
        self.preview = self.session->getPreviewClient();
        self.control = self.session->getControlClient();
        self.playback = self.session->getPlaybackClient();
        self.vplayback = self.session->getVideoPlaybackClient();
        self.aserver = self.session->getAudioServer();
        if (!self.preview || !self.control || !self.playback || !self.vplayback || !self.aserver) {
            SHLogInfo(SHLogTagSDK, @"SDK objects were nil.");
            retVal = ICH_NULL;
            break;
        }
        
        self.videoRange = NSMakeRange(0, VIDEO_BUFFER_SIZE);
        self.audioRange = NSMakeRange(0, AUDIO_BUFFER_SIZE);
        [self initResampler];
    } while (0);
    
    if (retVal == ICH_SUCCEED) {
        @synchronized (self) {
            self.isSHSDKInitialized = YES;
        }
        SHLogInfo(SHLogTagSDK, @"---INITIALIZE SHSDK Done---");
    } else {
        self.isSHSDKInitialized = NO;
        SHLogError(SHLogTagSDK, @"---INITIALIZE SHSDK Failed--- error code is:%d",retVal);
        
        if (self.session) {
            delete self.session;
            self.session = NULL;
        }
    }
    
    return retVal;
}

- (void)destroySHSDK {
    SHLogInfo(SHLogTagAPP, @"---START DESTROY SHSDK---");

    if (self.isSHSDKInitialized == NO) {
        return;
    }
    
    @synchronized (self) {
        self.isSHSDKInitialized = NO;
    }
    
    [self closeAudioServer];
    
    if (_resampler != nil) {
        _resampler->unInit();
        _resampler = nullptr;
    }
    
    if (self.session) {
        SHLogInfo(SHLogTagAPP, @"start destroy session.");
        self.session->destroySession();
        self.session->disableTutk();
        delete self.session;
        self.session = NULL;
        SHLogInfo(SHLogTagAPP, @"destroy session done.");
    }
    
    if (self.videoFrameBuffer) {
        delete self.videoFrameBuffer;
        self.videoFrameBuffer = NULL;
    }
    
    if (self.audioFrameBuffer) {
        delete self.audioFrameBuffer;
        self.audioFrameBuffer = NULL;
    }
    
    self.preview = NULL;
    self.control = NULL;
    self.playback = NULL;
    self.vplayback = NULL;
    self.aserver = NULL;
    
    SHLogInfo(SHLogTagAPP, @"---DESTROY SHSDK Done---");
}

- (int)tryConnectCamera:(NSString *)cameraUid devicePassword:(NSString *)devicePassword {
    cameraUid = [cameraUid uppercaseString];
    int retVal = ICH_NULL;
    
    SHLogInfo(SHLogTagSDK, @"start tryConnectCamera.");

    _session = new Session();
    if (_session == NULL) {
        SHLogError(SHLogTagSDK, @"Create session failed.");
        return retVal;
    }
    
    SHLogInfo(SHLogTagSDK, @"start loadTutkLibrary.");
    _session->loadTutkLibrary();
    SHLogInfo(SHLogTagSDK, @"end loadTutkLibrary.");
    
    string password = devicePassword ? devicePassword.UTF8String : "1234";
    
    SHLogInfo(SHLogTagSDK, @"start enableTutk.");
    retVal = _session->enableTutk(cameraUid.UTF8String, password, YES);
    SHLogInfo(SHLogTagSDK, @"end enableTutk.");

    if (retVal != ICH_SUCCEED) {
        SHLogInfo(SHLogTagSDK, @"enableTutk failed, retVal: %d", retVal);
        _session->destroySession();
        _session = NULL;
        
        return retVal;
    }
    
    SHLogInfo(SHLogTagSDK, @"end tryConnectCamera.");

    return retVal;
}

- (void)destroyTryConnectResource {
    SHLogInfo(SHLogTagSDK, @"start destroyTryConnectResource.");

    if (_session != NULL) {
        _session->disableTutk();
        _session->destroySession();
        _session = NULL;
    }
    
    SHLogInfo(SHLogTagSDK, @"end destroyTryConnectResource.");
}

- (void)disableTutk {
    if (self.session) {
        self.session->disableTutk();
    }
}

- (NSString *)getTutkConnectMode {
    NSString *mode = nil;
    
    if (self.session) {
        int tutkMode = self.session->getTutkConnectMode();
        mode = [[[SHCamStaticData instance] tutkModeDict] objectForKey:@(tutkMode)];
    }
    
    SHLogInfo(SHLogTagSDK, @"TutkConnectMode: %@", mode);
    return mode;
}

- (void)openSaveVideo {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"TestVideo"];
    [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
    Config::getInstance()->openSaveVideo(mediaDirectory.UTF8String, "OriginalVideo", "h264");
}

- (void)closeSaveVideo {
    Config::getInstance()->closeSaveVideo();
}

- (void)openSaveAudio {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"TestAudio"];
    [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
    
    Config::getInstance()->openSaveAudio(mediaDirectory.UTF8String, "recv", "send");
}

- (void)closeSaveAudio {
    Config::getInstance()->closeSaveAudio();
}

#pragma mark - Properties

#pragma mark - MEDIA
- (int)startMediaStreamWithEnableAudio:(BOOL)enableAudio camera:(SHCameraObject *)cameraObj {
    int startRetVal = ICH_NULL;
    
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return startRetVal;
    }
    
    bool disableAudio = enableAudio == YES ? false : true;
    
    SHLogInfo(SHLogTagSDK, @"start startMediaStream - H264.");

    Config::getInstance()->setPreviewCacheParam(1000, 200);
    SHH264StreamParameter param(1280, 720, 2000000, 30);

    ICatchVideoFormat *videoFormat = cameraObj.cameraProperty.videoFormat;
    ICatchAudioFormat *audioFormat = cameraObj.cameraProperty.audioFormat;
    
    if (videoFormat == nil || (enableAudio && audioFormat == nil)) {
        SHLogInfo(SHLogTagAPP, @"Video format or audio format is nil, need get stream info.");
        startRetVal = _preview->start(param, disableAudio);
        
        if (startRetVal == ICH_SUCCEED) {
            [self saveFormat2Database:cameraObj];
        }
    } else {
        SHLogInfo(SHLogTagAPP, @"Video format & audio format isn't nil, needn't get stream info.");
        startRetVal = _preview->start(param, disableAudio, videoFormat, audioFormat);
    }
    
    SHLogInfo(SHLogTagSDK, @"startMediaStream done, retVal : %d.", startRetVal);
//    if (startRetVal == ICH_SUCCEED) {
//        [self saveVideoFrameDataForTest];
//    }
    
    self.isStopped = NO;
    return startRetVal;
}

- (BOOL)setVideoQuality:(ICatchVideoQuality)quality {
    int retVal = ICH_NULL;
    
    if (_preview == nil) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    retVal = _preview->setVideoQuality(quality);
    SHLogInfo(SHLogTagAPP, @"Set video quality: %d", retVal);
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (int)previewPlay {
    int retVal = ICH_NULL;
    
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return retVal;
    }
    
    SHLogDebug(SHLogTagSDK, @"start previewPlay");
    retVal = _preview->play();
    SHLogDebug(SHLogTagSDK, @"previewPlay done, ret: %d", retVal);
    
    return retVal;
}

- (BOOL)stopMediaStream {
    @synchronized(self) {
        if (!self.isStopped) {
            int retVal = ICH_NULL;
            
            if(!_preview) {
                SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
                return retVal;
            }
            
//            fclose(_file);
            
            SHLogInfo(SHLogTagSDK, @"start stopMediaStream.");
            retVal = _preview->stop();
            SHLogInfo(SHLogTagSDK, @"stopMediaStream done, retVal : %d", retVal);
            
            if (retVal == ICH_SUCCEED) {
                self.isStopped = YES;
                return YES;
            } else {
                SHLogInfo(SHLogTagSDK, @"stopMediaStream failed.");
                return NO;
            }
        } else {
            return YES;
        }
    }
}

- (int)previewStop {
    int retVal = ICH_NULL;
    
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return retVal;
    }
    
    SHLogDebug(SHLogTagSDK, @"start previewStop");
    retVal = _preview->stop();
    SHLogDebug(SHLogTagSDK, @"previewStop done, ret: %d", retVal);
    
    return retVal;
}

- (BOOL)videoStreamEnabled {
    return (_preview && _preview->containsVideoStream() == true) ? YES : NO;
}

- (BOOL)audioStreamEnabled {
    return (_preview && _preview->containsAudioStream() == true) ? YES : NO;
}

- (ICatchVideoFormat)getVideoFormat {
    ICatchVideoFormat format;
    
    if (_preview) {
        _preview->getVideoFormat(format);
        
        SHLogInfo(SHLogTagSDK, @"video format: %d", format.getCodec());
        SHLogInfo(SHLogTagSDK, @"video w: %d, h: %d", format.getVideoW(), format.getVideoH());
        SHLogInfo(SHLogTagSDK, @"spsSize:%d, ppsSize: %d", format.getCsd_0_size(), format.getCsd_1_size());
        SHLogInfo(SHLogTagSDK, @"sps:%s, pps: %s", format.getCsd_0(), format.getCsd_1());
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return format;
}

- (ICatchAudioFormat)getAudioFormat {
    ICatchAudioFormat format;
    if (_preview) {
        _preview->getAudioFormat(format);
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return format;
}

- (void)saveFormat2Database:(SHCameraObject *)cameraObj {
    ICatchVideoFormat *videoFormat = [self cacheVideoFormat];
    ICatchAudioFormat *audioFormat = [self cacheAudioFormat];
    
    if (videoFormat && audioFormat) {
        cameraObj.cameraProperty.videoFormat = videoFormat;
        cameraObj.cameraProperty.audioFormat = audioFormat;
        
    }
}

- (ICatchVideoFormat *)cacheVideoFormat {
    ICatchVideoFormat format;
    if (_preview) {
        int ret = _preview->getVideoFormat(format);
        if (ret == ICH_SUCCEED) {
            return  new ICatchVideoFormat(format);
        } else {
            SHLogError(SHLogTagSDK, @"cacheVideoFormat failed, ret: %d", ret);
        }
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return NULL;
}

- (ICatchAudioFormat *)cacheAudioFormat {
    ICatchAudioFormat format;
    if (_preview) {
        int ret = _preview->getAudioFormat(format);
        if (ret == ICH_SUCCEED) {
            return  new ICatchAudioFormat(format);
        } else {
            SHLogError(SHLogTagSDK, @"cacheAudioFormat failed, ret: %d", ret);
        }
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return NULL;
}

- (void)saveVideoFrameDataForTest {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //        FILE *file;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"TestVideo"];
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        NSString *filePath = [mediaDirectory stringByAppendingPathComponent:@"test.mp4"];
        _file = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "wb+");
        SHLogInfo(SHLogTagSDK, @"filePath: %@", filePath);
        
        //        fwrite(self.videoFrameBuffer->getBuffer(), sizeof(char), self.videoFrameBuffer->getFrameSize(), _file);
        
        //        fclose(_file);
    });
}

- (SHAVData *)getVideoFrameData {
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return nil;
    }
    
    SHAVData *videoFrameData = nil;
    //SHLogDebug(SHLogTagSDK, @"getVideoFrameData begin");
    int retVal = _preview->getNextVideoFrame(self.videoFrameBuffer);
    //SHLogDebug(SHLogTagSDK, @"getVideoFrameData end, ret: %d", retVal);
//    SHLogDebug(SHLogTagSDK, @"video frame presentation time: %f", self.videoFrameBuffer->getPresentationTime());
    
    if (retVal == ICH_SUCCEED && self.videoFrameBuffer->getFrameSize() > 0) {
        [self.videoData setLength:_videoRange.length];
        [self.videoData replaceBytesInRange:_videoRange withBytes:self.videoFrameBuffer->getBuffer()];
        [self.videoData setLength:self.videoFrameBuffer->getFrameSize()];
        videoFrameData = [SHAVData cameraAVDataWithData:self.videoData andTime:self.videoFrameBuffer->getPresentationTime()];
        videoFrameData.isIFrame = self.videoFrameBuffer->getIsIFrame() ? YES : NO;
        
//        SHLogInfo(SHLogTagSDK, @"video frame presentation time: %f", self.videoFrameBuffer->getPresentationTime());
//        fwrite(self.videoFrameBuffer->getBuffer(), sizeof(char), self.videoFrameBuffer->getFrameSize(), _file);
        
    } else {
        SHLogError(SHLogTagSDK, @"getVideoFrameData failed : %d", retVal);
    }
    
    return videoFrameData;
}

- (SHAVData *)getAudioFrameData {
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return nil;
    }
    
    SHAVData *audioTrackData = nil;
    //SHLogDebug(SHLogTagSDK, @"getAudioFrameData begin");
    int retVal = _preview->getNextAudioFrame(self.audioFrameBuffer);
    //SHLogDebug(SHLogTagSDK, @"getAudioFrameData end, ret: %d", retVal);
    //SHLogDebug(SHLogTagSDK, @"audio track presentation time: %f",self.audioFrameBuffer->getPresentationTime());
    
    if (retVal == ICH_SUCCEED && self.audioFrameBuffer->getFrameSize() > 0) {
        [self.audioData setLength:_audioRange.length];
        [self.audioData replaceBytesInRange:_audioRange withBytes:self.audioFrameBuffer->getBuffer()];
        [self.audioData setLength:self.audioFrameBuffer->getFrameSize()];
        audioTrackData = [SHAVData cameraAVDataWithData:self.audioData andTime:self.audioFrameBuffer->getPresentationTime()];
    } else {
        SHLogError(SHLogTagSDK, @"getAudioFrameData failed : %d", retVal);
    }
    
    return audioTrackData;
}

- (BOOL)isMute {
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    return _preview->isMute();
}

- (BOOL)openAudio:(BOOL)isOpen {
    BOOL ret = NO;
    
    if (!_preview) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return ret;
    }
    
    if (isOpen) {
        ret = _preview->vocal() == ICH_SUCCEED ? YES : NO;
        SHLogInfo(SHLogTagSDK, @"enableAudio: %d", ret);
    } else {
        ret = _preview->mute() == ICH_SUCCEED ? YES : NO;
        SHLogInfo(SHLogTagSDK, @"disableAudio: %d", ret);
    }
    
    return ret;
}

- (BOOL)openAudioServer:(ICatchAudioFormat)audioFormat {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    SHLogInfo(SHLogTagSDK, @"openAudioServer start.");
    int retVal = _aserver->open(audioFormat);
    SHLogInfo(SHLogTagSDK, @"openAudioServer done, retVal : %d.", retVal);
    
    if (retVal != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"openAudioServer failed.");
    }
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)closeAudioServer {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    SHLogInfo(SHLogTagSDK, @"closeAudioServer start.");
    int retVal = _aserver->close();
    SHLogInfo(SHLogTagSDK, @"closeAudioServer done, retVal : %d.", retVal);
    
    if (retVal != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"openAudioServer failed.");
    }
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)startSendAudioFrame {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    SHLogInfo(SHLogTagSDK, @"startSendAudioFrame start.");
    int retVal = _aserver->startSend();
    SHLogInfo(SHLogTagSDK, @"startSendAudioFrame done, ret: %d.", retVal);
    
    if (retVal != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"startSendAudioFrame failed.");
    } else {
#if 0
        [self openSaveAudio];
#endif
    }

    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)stopSendAvdioFrame:(double)pts {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return YES;
    }
    
    SHLogInfo(SHLogTagSDK, @"stopSendAvdioFrame start.");
    int retVal = _aserver->stopSend(pts);
    SHLogInfo(SHLogTagSDK, @"stopSendAvdioFrame done, ret: %d.", retVal);
    
    if (retVal != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"stopSendAvdioFrame failed.");
    } else {
#if 0
        [self closeSaveAudio];
#endif
    }
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)readyCheck {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    return _aserver->readyCheck();
}

- (BOOL)sendAudioFrame:(ICatchFrameBuffer *)audioBuffer andDB:(double)db {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }

    SHLogDebug(SHLogTagSDK, @"sendAudioFrame start.");
    int retVal = _aserver->sendAudioFrame(audioBuffer);
    SHLogDebug(SHLogTagSDK, @"sendAudioFrame done, ret: %d.", retVal);
    
    if (retVal != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"sendAudioFrame failed.");
    }
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (void)setAECEnabled:(BOOL)enabled {
    if (!_aserver) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return;
    }
    
    SHLogInfo(SHLogTagSDK, @"setAECEnabled start.");
    _aserver->setAECEnabled(enabled);
    SHLogInfo(SHLogTagSDK, @"setAECEnabled done.");
}

#pragma mark - CONTROL
- (BOOL)setImagePath:(NSString *)path {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    NSString *photoPath = path;//[NSString stringWithFormat:@"%@", NSTemporaryDirectory()]; //[SHTool createMediaDirectoryWithPath:path][1];
    SHLogInfo(SHLogTagAPP, @"photoPath: %@", photoPath);
    int retVal = _control->setImagePath(photoPath.UTF8String);
    
    if (retVal == ICH_SUCCEED ) {
        SHLogDebug(SHLogTagSDK, @"setImagePath succeed.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"setImagePath failed, ret: %d.", retVal);
        return NO;
    }
}

- (BOOL)capturePhoto:(NSString *)imageName {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    string imgName = imageName.UTF8String;
    int retVal = _control->capture(imgName);
    
    if (retVal == ICH_SUCCEED ) {
        SHLogDebug(SHLogTagSDK, @"capturePhoto succeed.");
        //*imageName = [NSString stringWithFormat:@"%s", imgName.c_str()];
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"capturePhoto failed, ret: %d.", retVal);
        return NO;
    }
}

- (int)startVideoRecord {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    SHLogTRACE();
    
    int retVal = _control->startVideoRecord();
    SHLogInfo(SHLogTagSDK, @"startVideoRecord retVal: %d", retVal);
    
    return retVal;//==ICH_SUCCEED?YES:NO;
}

- (BOOL)stopVideoRecord {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    SHLogTRACE();
    
    int retVal = _control->stopVideoRecord();
    SHLogInfo(SHLogTagSDK, @"stopMovieRecord retVal: %d", retVal);
    
    return retVal==ICH_SUCCEED?YES:NO;
}

- (void)addObserver:(ICatchEventID)eventTypeId listener:(Listener *)listener isCustomize:(BOOL)isCustomize
{
    SHLogTRACE();
    if (listener && _control) {
        
        if (isCustomize) {
            SHLogInfo(SHLogTagAPP, @"add customize eventTypeId: %d", eventTypeId);
            _control->addCustomEventListener(eventTypeId, listener);
        } else {
            SHLogInfo(SHLogTagAPP, @"add eventTypeId: %d", eventTypeId);
            _control->addEventListener(eventTypeId, listener);
        }
    } else  {
        SHLogError(SHLogTagSDK, @"listener is null");
    }
}

- (void)addObserver:(SHObserver *)observer {
    if (observer.listener) {
        if (observer.isGlobal) {
            return;
        } else {
            if (_control) {
                if (observer.isCustomized) {
                    SHLogInfo(SHLogTagSDK, @"add customize eventTypeId: %d", observer.eventType);
                    _control->addCustomEventListener(observer.eventType, observer.listener);
                } else {
                    SHLogInfo(SHLogTagSDK, @"add eventTypeId: %d", observer.eventType);
                    _control->addEventListener(observer.eventType, observer.listener);
                }
            } else {
                SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
            }
        }
    } else  {
        SHLogError(SHLogTagSDK, @"listener is null");
    }
}

- (void)removeObserver:(SHObserver *)observer {
    if (observer.listener) {
        if (observer.isGlobal) {
            return;
        } else {
            if (_control) {
                if (observer.isCustomized) {
                    SHLogInfo(SHLogTagSDK, @"Remove customize eventTypeId: %d", observer.eventType);
                    _control->delCustomEventListener(observer.eventType, observer.listener);
                } else {
                    SHLogInfo(SHLogTagSDK, @"Remove eventTypeId: %d", observer.eventType);
                    _control->delEventListener(observer.eventType, observer.listener);
                }
            } else {
                SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
            }
            
        }
    } else  {
        SHLogError(SHLogTagSDK, @"listener is null");
    }
}

- (void)removeObserver:(ICatchEventID)eventTypeId listener:(Listener *)listener isCustomize:(BOOL)isCustomize
{
    SHLogTRACE();
    if (listener && _control) {
        if (isCustomize) {
            _control->delCustomEventListener(eventTypeId, listener);
        } else {
            _control->delEventListener(eventTypeId, listener);
        }
    } else  {
        SHLogError(SHLogTagSDK, @"listener is null");
    }
}

- (BOOL)formatSD {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    int retVal = ICH_SUCCEED;
    retVal = _control->formatSDCard();
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (BOOL)factoryReset {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    int retVal = ICH_SUCCEED;
    retVal = _control->factoryReset();
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

- (NSData *)requestThumbnail:(ICatchFile *)file andPropertyID:(int)propertyID {
    NSData *retData = nil;
    
    do {
        if (!file || !_control) {
            SHLogError(SHLogTagSDK, @"file is NULL or SHSDK doesn't working!!!");
            break;
        }
        
        ICatchFrameBuffer *thumbBuf = new ICatchFrameBuffer(640*360*2);

        if (thumbBuf == NULL) {
            SHLogError(SHLogTagAPP, @"new failed");
            break;
        }
        
        ICatchTransProperty *property = new ICatchTransProperty();
        property->setPropertyID(propertyID);
        property->setParam(file->getFileHandle());
        property->setDataSize(file->getFileThumbSize());
        
        int ret = _control->getTransThumbnail(*property, thumbBuf);
        
        if (ICH_BUF_TOO_SMALL == ret) {
            SHLogError(SHLogTagSDK, @"ICH_BUF_TOO_SMALL");
            break;
        }
        if (thumbBuf->getFrameSize() <= 0) {
            SHLogError(SHLogTagSDK, @"thumbBuf's data size <= 0, ret: %d", ret);
            break;
        }
        //这里进行转换，将thumbBuf转换为NSData类型，作为后续转换成image使用的类型
        retData = [NSData dataWithBytes:thumbBuf->getBuffer() length:thumbBuf->getFrameSize()];
        
        delete thumbBuf;
        thumbBuf = NULL;
        
        delete property;
        property = NULL;
    } while (0);

    return retData;
}

- (BOOL)setupWiFiWithSSID:(NSString *)ssid password:(NSString *)password {
    if (!_control) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return NO;
    }
    
    if (ssid == nil || password == nil) {
        SHLogError(SHLogTagAPP, @"ssid or password is nil.");
        return NO;
    }
    
    int retVal = ICH_SUCCEED;
    retVal = _control->setWiFiInfo(ssid.UTF8String, password.UTF8String);
    
    return retVal == ICH_SUCCEED ? YES : NO;
}

#pragma mark - PLAYBACK
- (BOOL)deleteFile:(ICatchFile *)f
{
    int ret = -1;
    if (!f || !_playback) {
        SHLogError(SHLogTagSDK, @"Invalid ICatchFile pointer used for deleting. or SHSDK doesn't working!!!");
        return NO;
    }
    
    switch (f->getFileType()) {
        case ICH_FILE_TYPE_IMAGE:
        case ICH_FILE_TYPE_VIDEO:
            ret = _playback->deleteFile(f);
            break;
            
        default:
            break;
    }
    
    if (ret != ICH_SUCCEED && ret != -17) {
        SHLogError(SHLogTagSDK, @"Delete failed, ret: %d", ret);
        return NO;
    } else {
        return YES;
    }
}

- (NSString *)downloadFile:(ICatchFile)f path:(NSString *)path {
    if (/*!f ||*/ !_playback) {
        SHLogError(SHLogTagSDK, @"f is NULL or SHSDK doesn't working!!!");
        return nil;
    }
    
    NSString *fileName = [NSString stringWithUTF8String:f.getFileName().c_str()];
#if 1
    NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
#else
    NSString *fileDirectory = nil;
    if (f.getFileType() == ICH_FILE_TYPE_VIDEO /*[fileName hasSuffix:@".MP4"] || [fileName hasSuffix:@".MOV"]*/) {
        fileDirectory = [SHTool createMediaDirectoryWithPath:path][2];
    } else {
        fileDirectory = [SHTool createMediaDirectoryWithPath:path][1];
    }
    NSString *locatePath = [fileDirectory stringByAppendingPathComponent:fileName];
#endif
    int ret = _playback->downloadFile(f, [locatePath cStringUsingEncoding:NSUTF8StringEncoding]);
    
    SHLogInfo(SHLogTagSDK, @"Download File, ret : %d", ret);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"Download File Failed.");
        locatePath = nil;
    } else {
        SHLogInfo(SHLogTagSDK, @"locatePath: %@", locatePath);
        
        NSString *filePath = [NSString stringWithFormat:@"%s", f.getFilePath().c_str()];
        SHLogInfo(SHLogTagSDK, @"set file path %@ to 0xD83B", filePath);
//        [self setCustomizeStringProperty:0xD83B value:filePath];
    }
    
    return locatePath;
}

- (long)getDownloadedFileSize:(NSString *)filePath {
    if (!filePath || !_playback) {
        SHLogError(SHLogTagSDK, @"filePath is nil or SHSDK doesn't working!!!");
        return -1;
    }
    
    return _playback->getDownloadedFileSize(filePath.UTF8String);
}

- (BOOL)cancelDownloadFile:(ICatchFile )f
{
	
    if (!_playback) {
        SHLogError(SHLogTagSDK, @"f is NULL or SHSDK doesn't working!!!");
        return NO;
    }
    
    NSString *fileName = [NSString stringWithUTF8String:f.getFileName().c_str()];
    NSString *locatePath = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    
    int retVal = _playback->cancelDownloadFile(f, [locatePath cStringUsingEncoding:NSUTF8StringEncoding]);
    SHLogInfo(SHLogTagSDK, @"Downloading Canceled, ret : %d", retVal);
    
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"Downloading succeed to cancel.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"Downloading failed to cancel.");
        return NO;
    }
}

- (map<string, int>)getFilesStorageInfoWithStartDate:(NSString *)startDate andEndDate:(NSString *)endDate success:(BOOL *)isSuccess {
    map<string, int> storageInfoMap;

    if (!_playback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return storageInfoMap;
    }
    
    int retVal = _playback->getFilesStorageInfo(startDate.UTF8String, endDate.UTF8String, storageInfoMap);
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"getFilesStorageInfoWithStartDate succeed.");
        *isSuccess = YES;
    } else {
        SHLogError(SHLogTagSDK, @"getFilesStorageInfoWithStartDate failed, ret: %d.", retVal);
        *isSuccess = NO;
    }

    SHLogInfo(SHLogTagSDK, "storageSize: %zd", storageInfoMap.size());
    return storageInfoMap;
}

- (map<string, int>)getDailyFileCountWithStartDate:(NSString *)startDate andDaysNum:(int)daysNum {
    map<string, int> dailyFileCountMap;
    
    if (!_playback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return dailyFileCountMap;
    }
    
    int retVal = _playback->getDailyFileCount(startDate.UTF8String, daysNum, dailyFileCountMap);
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"getFilesStorageInfoWithStartDate succeed.");
    } else {
        SHLogError(SHLogTagSDK, @"getFilesStorageInfoWithStartDate failed, ret: %d.", retVal);
    }
    
    SHLogInfo(SHLogTagSDK, "fileSize: %zd", dailyFileCountMap.size());
    return dailyFileCountMap;
}

- (vector<ICatchFile>)listFilesWhithDate:(string)date andStartIndex:(int)startIndex andNumber:(int)number {
    vector<ICatchFile> list;

    if (!_playback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return list;
    }
    
    int retVal = _playback->listFiles(date, startIndex, number, list);
    if (retVal == ICH_SUCCEED) {
        SHLogDebug(SHLogTagSDK, @"listFilesWhithDate succeed.");
    } else {
        SHLogError(SHLogTagSDK, @"listFilesWhithDate failed, ret: %d.", retVal);
    }
    
    SHLogInfo(SHLogTagSDK, "listSize: %zd", list.size());
    return list;
}

- (BOOL)setFileTag:(ICatchFile *)f andIsFavorite:(BOOL)favorite {
    if (!f || !_playback) {
        SHLogError(SHLogTagSDK, @"f is NULL or SHSDK doesn't working!!!");
        return NO;
    }
    
    bool isFavorite = favorite == YES ? true : false;
    int retVal = _playback->setFileTag(f, isFavorite);
    if (retVal == ICH_SUCCEED ) {
        SHLogDebug(SHLogTagSDK, @"setFileTag succeed.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"setFileTag failed, ret: %d.", retVal);
        return NO;
    }
}

- (BOOL)getFilesFilter:(ICatchFileFilter *)filter {
    if (!filter || !_playback) {
        SHLogError(SHLogTagSDK, @"filter is NULL or SHSDK doesn't working!!!");
        return NO;
    }
    
    //检测类型
    //文件类型
    //收藏
    int retVal = _playback->getFilesFilter(*filter);
    if (retVal == ICH_SUCCEED ) {
        SHLogDebug(SHLogTagSDK, @"getFileFilter succeed.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"getFileFilter failed, ret: %d.", retVal);
        return NO;
    }
}

- (BOOL)setFilesFilter:(ICatchFileFilter *)filter {
    if (!filter || !_playback) {
        SHLogError(SHLogTagSDK, @"filter is NULL or SHSDK doesn't working!!!");
        return NO;
    }
    
    int retVal = _playback->setFilesFilter(*filter);
    if (retVal == ICH_SUCCEED ) {
        SHLogDebug(SHLogTagSDK, @"setFilesFilter succeed.");
        return YES;
    } else {
        SHLogError(SHLogTagSDK, @"setFilesFilter failed, ret: %d.", retVal);
        return NO;
    }
}

#pragma mark - Video PB
- (double)play:(ICatchFile *)file {
    double videoFileTotalSecs = 0;
    if (!_vplayback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return 0;
    }
    
    int ret = _vplayback->play(*file);
    if (ret != ICH_SUCCEED) {
        SHLogError(SHLogTagSDK, @"play failed.");
        videoFileTotalSecs = ret;
    } else {
        _vplayback->getLength(videoFileTotalSecs);
    }
    
    return videoFileTotalSecs;
}

- (BOOL)stop {
    int ret = ICH_NULL;
    if (_vplayback) {
        ret = _vplayback->stop();
    }
    
    SHLogInfo(SHLogTagSDK, @"STOP %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)pause {
    int ret = ICH_NULL;
    if (_vplayback != NULL) {
        ret = _vplayback->pause();
    }
    
    SHLogInfo(SHLogTagSDK, @"PAUSE %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)resume {
    int ret = ICH_NULL;
    if (_vplayback) {
        ret = _vplayback->resume();
    }
    
    SHLogInfo(SHLogTagSDK, @"RESUME %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)seek:(double)point {
    int ret = ICH_NULL;
    if (_vplayback) {
        SHLogInfo(SHLogTagSDK, @"call seek...");
        ret = _vplayback->seek(point);
    }
    
    SHLogInfo(SHLogTagSDK, @"SEEK %@", ret == ICH_SUCCEED ? @"Succeed.":@"Failed.");
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)videoPlaybackStreamEnabled {
    return (_vplayback && _vplayback->containsVideoStream() == true) ? YES : NO;
}

- (BOOL)audioPlaybackStreamEnabled {
    return (_vplayback && _vplayback->containsAudioStream() == true) ? YES : NO;
}

- (ICatchVideoFormat)getPlaybackVideoFormat {
    ICatchVideoFormat format;
    if (_vplayback) {
        _vplayback->getVideoFormat(format);
        
        SHLogInfo(SHLogTagSDK, @"video format: %d", format.getCodec());
        SHLogInfo(SHLogTagSDK, @"video w,h: %d, %d", format.getVideoW(), format.getVideoH());
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return format;
}

- (ICatchAudioFormat)getPlaybackAudioFormat {
    ICatchAudioFormat format;
    if (_vplayback) {
        _vplayback->getAudioFormat(format);
    } else {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
    }
    
    return format;
}

- (SHAVData *)getPlaybackVideoFrameData {
    if (!_vplayback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return nil;
    }
    
    SHAVData *videoFrameData = nil;
    SHLogDebug(SHLogTagSDK, @"getPlaybackVideoFrameData begin");
    int retVal = _vplayback->getNextVideoFrame(self.videoFrameBuffer);
    SHLogDebug(SHLogTagSDK, @"getPlaybackVideoFrameData end, ret: %d", retVal);
    SHLogDebug(SHLogTagSDK, @"video frame presentation time: %f", self.videoFrameBuffer->getPresentationTime());
    
    if (retVal == ICH_SUCCEED) {
        [self.videoData setLength:_videoRange.length];
        [self.videoData replaceBytesInRange:_videoRange withBytes:self.videoFrameBuffer->getBuffer()];
        [self.videoData setLength:self.videoFrameBuffer->getFrameSize()];
        videoFrameData = [SHAVData cameraAVDataWithData:self.videoData andTime:self.videoFrameBuffer->getPresentationTime()];
        videoFrameData.isIFrame = self.videoFrameBuffer->getIsIFrame() ? YES : NO;
    } else {
        SHLogError(SHLogTagSDK, @"getPlaybackVideoFrameData failed : %d", retVal);
    }
    
    return videoFrameData;
}

- (SHAVData *)getPlaybackAudioFrameData {
    if (!_vplayback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return nil;
    }
    
    SHAVData *audioTrackData = nil;
    SHLogDebug(SHLogTagSDK, @"getPlaybackAudioFrameData begin");
    int retVal = _vplayback->getNextAudioFrame(self.audioFrameBuffer);
    SHLogDebug(SHLogTagSDK, @"getPlaybackAudioFrameData end, ret: %d", retVal);
    SHLogDebug(SHLogTagSDK, @"audio track presentation time: %f",self.audioFrameBuffer->getPresentationTime());
    
    if (retVal == ICH_SUCCEED) {
        [self.audioData setLength:_audioRange.length];
        [self.audioData replaceBytesInRange:_audioRange withBytes:self.audioFrameBuffer->getBuffer()];
        [self.audioData setLength:self.audioFrameBuffer->getFrameSize()];
        audioTrackData = [SHAVData cameraAVDataWithData:self.audioData andTime:self.audioFrameBuffer->getPresentationTime()];
    } else {
        SHLogError(SHLogTagSDK, @"getPlaybackAudioFrameData failed : %d", retVal);
    }
    
    return audioTrackData;
}

- (ICatchFrameBuffer *)getPlaybackAudioFrameData1 {
    if (!_vplayback) {
        SHLogError(SHLogTagSDK, @"SHSDK doesn't work!!!");
        return nil;
    }
    
    int retVal = _vplayback->getNextAudioFrame(self.audioFrameBuffer);
    
    if (retVal == ICH_SUCCEED) {
        
        return self.audioFrameBuffer;
    } else {
        //        AppLog(@"getNextAudioFrame failed : %d", retVal);
        return NULL;
    }
}

- (smarthome::EnvironmentCheck *)checkInstance {
    if (_checkInstance == nil) {
        _checkInstance = new EnvironmentCheck(*(_session));
    }
    
    return _checkInstance;
}

- (BOOL)startPushMessageTest:(NSInteger)totalCount interval:(NSTimeInterval)interval {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    return self.checkInstance->startPushMessageTest((int)totalCount, interval) == ICH_SUCCEED ? YES : NO;
}

- (BOOL)stopPushMessageTest {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    return self.checkInstance->stopPushMessageTest() == ICH_SUCCEED ? YES : NO;
}

- (BOOL)avSpeedTest:(int)timeInSecs avergeSpeed:(double *)averageSpeed {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    int ret = self.checkInstance->avSpeedTest(timeInSecs, *averageSpeed);
    SHLogInfo(SHLogTagAPP, @"avAverageSpeed: %f", *averageSpeed);
    
    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)cancelAvSpeedTest {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    return self.checkInstance->cancelAvSpeedTest() == ICH_SUCCEED ? YES : NO;
}

- (BOOL)talkSpeedTest:(int)timeInSecs avergeSpeed:(double *)averageSpeed {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    int ret = self.checkInstance->talkSpeedTest(timeInSecs, *averageSpeed);
    SHLogInfo(SHLogTagAPP, @"talkAverageSpeed: %f", *averageSpeed);

    return ret == ICH_SUCCEED ? YES : NO;
}

- (BOOL)cancelTalkSpeedTest {
    if (self.checkInstance == nil) {
        SHLogError(SHLogTagAPP, @"checkInstance is nil.");
        return NO;
    }
    
    return self.checkInstance->cancelTalkSpeedTest() == ICH_SUCCEED ? YES : NO;
}

@end
