//
//  SHPVOperateManageer.m
//  SmartHome
//
//  Created by ZJ on 2017/4/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHStreamOperate.h"
#import "SHSDKEventListener.hpp"
#import "SHObserver.h"
#import "H264Decoder.h"
#import "HYOpenALHelper.h"
#import "PCMDataPlayer.h"
#import "SHAudioUnit.h"
#import "SHAudioUnitRecord.h"
#import "SHVideoFormat.h"
#import "XJLocalAssetHelper.h"
#import "SHNetworkManager+SHCamera.h"

static const NSTimeInterval kBufferingMinTime = 1.0;
static const NSTimeInterval kBufferingMaxTime = 10.0;

@interface SHStreamOperate ()

@property (nonatomic) BOOL enableDecoder;
@property (nonatomic, getter = isPVRun) BOOL PVRun;
@property (nonatomic, getter = isAudioRun) BOOL AudioRun;
@property (nonatomic, weak) AVSampleBufferDisplayLayer *avslayer;

@property (nonatomic) dispatch_queue_t streamQ;
@property (nonatomic) dispatch_group_t streamGroup;
@property (nonatomic) dispatch_queue_t audioQueue;
@property (nonatomic) dispatch_queue_t videoQueue;

@property (nonatomic, strong) H264Decoder *h264Decoder;
@property (nonatomic, strong) HYOpenALHelper *audioHelper;
@property (nonatomic, strong) SHObserver *streamObserver;
@property (nonatomic, strong) PCMDataPlayer *pcmPl;
@property (nonatomic) SHAudioUnit *audioUnit;
@property (nonatomic) SHAudioUnitRecord *audioUnitRecord;

@property (nonatomic) void (^bufferingBlock)(BOOL isBuffering, BOOL timeout);
@property (nonatomic, strong) NSDate *currentDate;

@property (nonatomic, strong) NSMutableData *currentVideoData;
@property (nonatomic, strong) UIImage *lastFrameImage;

@end

@implementation SHStreamOperate

#pragma mark - Initialization
- (instancetype)initWithCameraObject:(SHCameraObject *)shCamObj
{
    self = [super init];
    if (self) {
        self.shCamObj = shCamObj;
        self.enableDecoder = YES;
    }
    return self;
}

- (dispatch_queue_t)streamQ {
    if (!_streamQ) {
        _streamQ = dispatch_queue_create("SmartHome.GCD.Queue.Stream", DISPATCH_QUEUE_SERIAL);
    }
    
    return _streamQ;
}

- (dispatch_group_t)streamGroup {
    if (!_streamGroup) {
        _streamGroup = dispatch_group_create();
    }
    
    return _streamGroup;
}

- (dispatch_queue_t)audioQueue {
    if (!_audioQueue) {
        _audioQueue = dispatch_queue_create("SmartHome.GCD.Queue.Stream.Audio", 0);
    }
    
    return _audioQueue;
}

- (dispatch_queue_t)videoQueue {
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("SmartHome.GCD.Queue.Stream.Video", 0);
    }
    
    return _videoQueue;
}

- (H264Decoder *)h264Decoder {
    if (!_h264Decoder) {
        _h264Decoder = [[H264Decoder alloc] init];
    }
    
    return _h264Decoder;
}

- (HYOpenALHelper *)audioHelper {
    if (!_audioHelper) {
        _audioHelper = [[HYOpenALHelper alloc] init];
    }
    
    return _audioHelper;
}

- (SHAudioUnit *)audioUnit {
    if (_audioUnit == nil) {
        _audioUnit = [[SHAudioUnit alloc] init];
        _audioUnit.shCameraObj = _shCamObj;
    }
    
    return _audioUnit;
}

- (SHAudioUnitRecord *)audioUnitRecord {
    if (_audioUnitRecord == nil) {
        _audioUnitRecord = [[SHAudioUnitRecord alloc] initWithCameraObj:_shCamObj];
    }
    
    return _audioUnitRecord;
}

- (NSMutableData *)currentVideoData {
    if (_currentVideoData == nil) {
        _currentVideoData = [NSMutableData data];
    }
    
    return _currentVideoData;
}

#pragma mark - Meida Control
- (void)initAVSLayer:(AVSampleBufferDisplayLayer *)avslayer bufferingBlock:(void (^)(BOOL isBuffering, BOOL timeout))bufferingBlock {
    if (!avslayer) {
        self.enableDecoder = NO;
    } else {
        self.enableDecoder = YES;
        self.avslayer = avslayer;
        self.bufferingBlock = bufferingBlock;
    }
}

- (void)startMediaStreamWithEnableAudio:(BOOL)enableAudio file:(ICatchFile *)file successBlock:(void (^)())successBlock failedBlock:(void (^)(NSInteger errorCode))failedBlock target:(id)aTarget streamCloseCallback:(SEL)streamCloseCallback {
    _AudioRun = enableAudio;
    
    if (!_avslayer) {
        SHLogError(SHLogTagAPP, @"avslayer is nil");
        if (failedBlock) {
            failedBlock(ICH_NULL);
        }
        return;
    }
    
    if (file) {
        
    }
    
    if (_PVRun) {
        SHLogInfo(SHLogTagAPP, @"streaming already started.");
        if (failedBlock) {
            failedBlock(ICH_NULL);
        }
        return;
    }
    
    dispatch_time_t timeOutCount = dispatch_time(DISPATCH_TIME_NOW, 5ull * NSEC_PER_SEC);
    dispatch_async(self.streamQ, ^{
        if (dispatch_semaphore_wait(_shCamObj.semaphore, timeOutCount) != 0) {
            if (failedBlock) {
                failedBlock(ICH_NULL);
            }
            return;
        }
        
        int ret = [_shCamObj.sdk startMediaStreamWithEnableAudio:enableAudio camera:_shCamObj];
        
        if (ret != ICH_SUCCEED) {
            dispatch_semaphore_signal(_shCamObj.semaphore);
            if (failedBlock) {
                failedBlock(ret);
            }
            return;
        } else {
            /*
            SHSDKEventListener *lister = new SHSDKEventListener(aTarget, streamCloseCallback);
            self.streamObserver = [SHObserver cameraObserverWithListener:lister eventType:ICATCH_EVENT_MEDIA_STREAM_CLOSED isCustomized:NO isGlobal:NO];
            [_shCamObj.sdk addObserver:self.streamObserver];
            */
            [self play];
            if (_shCamObj.cameraProperty.serverOpened == NO) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [_shCamObj openAudioServer];
                });
            }

            if (successBlock) {
                successBlock();
            }
        }
    });
}

- (void)saveVideoForTest {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"Video"];
    [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
}

- (void)playbackVideo {
    ICatchVideoFormat format = [_shCamObj.sdk getVideoFormat];
    
    if (format.getCodec() == ICATCH_CODEC_JPEG) {
        SHLogInfo(SHLogTagAPP, @"playbackVideoMJPEG");
        [self playbackVideoMJPEG];
    } else if (format.getCodec() == ICATCH_CODEC_H264) {
        SHLogInfo(SHLogTagAPP, @"playbackVideoH264");
        
        [self playbackVideoH264:format];
    } else {
        SHLogError(SHLogTagAPP, @"Unknown codec.");
    }
    
    SHLogInfo(SHLogTagAPP, @"Break video");
}

- (void)playbackVideoMJPEG {
    
}

- (void)playbackVideoH264:(ICatchVideoFormat)format {
    NSRange headerRange = NSMakeRange(0, 4);
    NSMutableData *headFrame = nil;
    uint32_t nalSize = 0;
    
    while (_PVRun) {
        
        //flush avslayer when active from background
        if (self.avslayer.status == AVQueuedSampleBufferRenderingStatusFailed) {
            [self.avslayer flush];
        }
        
        // HW decode
        if (![self.h264Decoder initH264EnvWithSPSSize:format.getCsd_0_size() sps:format.getCsd_0() ppsSize:format.getCsd_1_size() pps:format.getCsd_1()]) {
            SHLogError(SHLogTagAPP, @"initH264Env failed.");
            break;
        }
        
//        for(;;) {
//            @autoreleasepool {
//                // 1st frame contains sps & pps data.
//
//                SHAVData *shData = [_shCamObj.sdk getVideoFrameData];
//                //SHLogDebug(SHLogTagAPP, @"shData length: %zd", shData.data.length);
//                if (shData.data.length > 0 || !_PVRun) {
//                    NSUInteger loc = format.getCsd_0_size() + format.getCsd_1_size();
//                    nalSize = (uint32_t)(shData.data.length - loc - 4);
//                    NSRange iRange = NSMakeRange(loc, shData.data.length - loc);
//                    const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
//                        (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
//                    headFrame = [NSMutableData dataWithData:[shData.data subdataWithRange:iRange]];
//                    [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
//
//                    if (_enableDecoder) {
//                        [self.h264Decoder decodeAndDisplayH264Frame:headFrame andAVSLayer:self.avslayer];
//                    }
//
//                    [self resetCurrentDate];
//                    break;
//                }
//            }
//        }
        [self resetCurrentDate];
#if 0
        BOOL first = YES;
        NSUInteger locLength = 0;
#endif
        while (_PVRun) {
            @autoreleasepool {

                SHAVData *shData = [_shCamObj.sdk getVideoFrameData];
                //SHLogDebug(SHLogTagAPP, @"shData length: %zd", shData.data.length);
                [self calcTimeDifference];
                
                if (shData.data.length > 0 && _PVRun) {
                    if (shData.isIFrame) {
#if 0
                        if (first) {
                            locLength = [self parseSPSPPS:shData.data];
                            first = NO;
                        }
                        NSUInteger loc = locLength;
#endif
                        NSUInteger loc = format.getCsd_0_size() + format.getCsd_1_size();
                        nalSize = (uint32_t)(shData.data.length - loc - 4);
                        NSRange iRange = NSMakeRange(loc, shData.data.length - loc);
                        const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                            (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                        headFrame = [NSMutableData dataWithData:[shData.data subdataWithRange:iRange]];
                        [headFrame replaceBytesInRange:headerRange withBytes:lengthBytes];
                        
//                        if (_enableDecoder) {
                            [self.h264Decoder decodeAndDisplayH264Frame:headFrame andAVSLayer:self.avslayer];
//                        }
                        [self recordCurrentVideoFrame:headFrame];
                    } else {
                        nalSize = (uint32_t)(shData.data.length - 4);
                        const uint8_t lengthBytes[] = {(uint8_t)(nalSize>>24),
                            (uint8_t)(nalSize>>16), (uint8_t)(nalSize>>8), (uint8_t)nalSize};
                        [shData.data replaceBytesInRange:headerRange withBytes:lengthBytes];
                        
//                        if (_enableDecoder) {
                            [self.h264Decoder decodeAndDisplayH264Frame:shData.data andAVSLayer:self.avslayer];
//                        }
                    }
                    
                    [self resetCurrentDate];
                } else {
                    [NSThread sleepForTimeInterval:0.005];
                }
            }
        }
        
        [self getLastFrameImage];
        [self.h264Decoder clearH264Env];
    }
}

const uint8_t KStartCode[4] = {0, 0, 0, 1};
- (NSUInteger)parseSPSPPS:(NSData *)data {
    uint8_t *bufferBegin = (uint8_t *)data.bytes + 4;
    uint8_t *bufferEnd = (uint8_t *)data.bytes + data.length;
    
    NSInteger spsSize = 0;
    NSInteger ppsSize = 0;
    while (bufferBegin != bufferEnd) {
        if (*bufferBegin == 0x01) {
            if (memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                NSInteger packetSize = bufferBegin - (uint8_t *)data.bytes - 3;
                
                int nalType = *((uint8_t *)data.bytes + 4 + spsSize) & 0x1F;
                switch (nalType) {
                    case 0x05:
                        NSLog(@"Nal type is IDR frame");
                        break;
                        
                    case 0x07:
                        NSLog(@"Nal type is SPS");
                        spsSize = packetSize;
                        break;
                        
                    case 0x08:
                        NSLog(@"Nal type is PPS");
                        ppsSize = packetSize - spsSize;
                        break;
                        
                    default:
                        NSLog(@"Nal type is B/P frame");
                        break;
                }
                
//                if (spsSize == 0) {
//                    spsSize = packetSize;
////                    NSLog(@"sps size: %ld", (long)spsSize);
////                    printf("sps: ");
////                    for (int i = 0; i < spsSize; i++) {
////                        printf("0x%x ", ((uint8_t *)data.bytes)[i]);
////                    }
////                    printf("\n");
//                } else {
//                    ppsSize = packetSize - spsSize;
////                    NSLog(@"pps size: %ld", (long)ppsSize);
////                    printf("pps: ");
////                    for (int i = 0; i < ppsSize; i++) {
////                        printf("0x%x ", ((uint8_t *)data.bytes + spsSize)[i]);
////                    }
////                    printf("\n");
//                    break;
//                }
            }
        }
        ++bufferBegin;
    }
    
    if (![self.h264Decoder initH264EnvWithSPSSize:(int)spsSize sps:(uint8_t *)data.bytes ppsSize:(int)ppsSize pps:((uint8_t *)data.bytes + spsSize)]) {
        SHLogError(SHLogTagAPP, @"initH264Env failed.");
    }
    
    return spsSize + ppsSize;
}

- (UIImage *)getLastFrameImage {
    UIImage *lastImage = nil;
    
    if (self.currentVideoData.length > 0) {
        lastImage = [self.h264Decoder imageFromPixelBufferRef:self.currentVideoData];
        SHLogInfo(SHLogTagAPP, @"Current preview last image: %@", lastImage);
        _lastFrameImage = lastImage;
    }
    
    return lastImage;
}

- (void)updatePreviewThumbnail {
    UIImage *lastImage = [self getLastFrameImage];

    if (lastImage != nil) {
        // compess original image
        NSData *coverData = UIImageJPEGRepresentation(lastImage, 0.5);
        UIImage *thumbnail = [[UIImage alloc] initWithData:coverData];
        
        if (thumbnail != nil) {
            self.shCamObj.camera.thumbnail = thumbnail;
            
            // Save data to sqlite
            NSError *error = nil;
            if (![self.shCamObj.camera.managedObjectContext save:&error]) {
                SHLogError(SHLogTagAPP, @"Unresolved error %@, %@", error, [error userInfo]);
#ifdef DEBUG
                abort();
#endif
            } else {
                SHLogInfo(SHLogTagAPP, @"Saved to sqlite.");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kNeedReloadDataBase];
            }
        }
    }
}

- (void)uploadPreviewThumbnailToServer {
    UIImage *lastImage = _lastFrameImage;

    if (lastImage != nil) {
        // compess original image
        NSData *coverData = UIImageJPEGRepresentation(lastImage, 0.5);
        
        if (coverData != nil) {
            // upload thumbnail to server
            [[SHNetworkManager sharedNetworkManager] updateCameraCoverByCameraID:self.shCamObj.camera.id andCoverData:coverData completion:^(BOOL isSuccess, id  _Nonnull result) {
                if (isSuccess) {
                    NSLog(@"update device cover success");
                } else {
                    NSLog(@"update device cover failure");
                }
                
                self.currentVideoData.length = 0;
                _currentVideoData = nil;
                _lastFrameImage = nil;
            }];
        }
    }
}

- (void)recordCurrentVideoFrame:(NSData *)data {
    self.currentVideoData.length = 0;
    [self.currentVideoData appendData:data];
}

- (void)calcTimeDifference {
    NSDate *curDate = [NSDate date];
    NSTimeInterval elapse = [curDate timeIntervalSinceDate:self.currentDate];
    
    if (elapse > kBufferingMaxTime) {
        if (self.bufferingBlock) {
            // FIXME: - timeout 未处理
            self.bufferingBlock(NO, NO);
            _isBuffering = NO;
            
            self.currentDate = [NSDate date];
        }
    } else {
        if (elapse > kBufferingMinTime && !_isBuffering) {
            _isBuffering = YES;
            if (self.bufferingBlock) {
                self.bufferingBlock(_isBuffering, NO);
            }
        }
    }
}

- (void)resetCurrentDate {
    self.currentDate = [NSDate date];
    
    if (_isBuffering) {
        _isBuffering = NO;
        if (self.bufferingBlock) {
            self.bufferingBlock(_isBuffering, NO);
        }
    }
}

- (void)playbackAudio {
    ICatchAudioFormat format = [_shCamObj.sdk getAudioFormat];
    
    SHLogInfo(SHLogTagAPP, @"freq: %d, chl: %d, bit:%d", format.getFrequency(), format.getNChannels(), format.getSampleBits());
    
    if (![self.audioHelper initOpenAL:format.getFrequency() channel:format.getNChannels() sampleBit:format.getSampleBits()]) {
        SHLogError(SHLogTagAPP, @"Init OpenAL failed.");
        return;
    }
    
    while (_PVRun) {
        @autoreleasepool {
            if (_shCamObj.cameraProperty.isMute/*[_shCamObj.sdk isMute]*/) {
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
 
#if APP_DEBUG
//            NSDate *begin = [NSDate date];
//            SHAVData *audioData = [_shCamObj.camera.sdk getAudioFrameData];
//            NSDate *end = [NSDate date];
//            NSTimeInterval elapse = [end timeIntervalSinceDate:begin];
#else
//            SHAVData *audioData = [_shCamObj.sdk getAudioFrameData];
#endif
//            SHLogDebug(SHLogTagAPP, @"[A]Get %lu, elapse: %f", (unsigned long)audioData.data.length, elapse);
			SHAVData *audioData = [_shCamObj.sdk getAudioFrameData];
            if (audioData.data.length > 0 && _enableDecoder) {
                [self.audioHelper insertPCMDataToQueue:audioData.data.bytes
                                                  size:audioData.data.length];
                [self.audioHelper play];
            }
        }
    }
    
    [self.audioHelper clean];
    self.audioHelper = nil;
    
    SHLogInfo(SHLogTagAPP, @"Break audio");
}

- (void)playbackAudio1
{
    NSMutableData *audioBuffer = [[NSMutableData alloc] init];
    
    ICatchAudioFormat format = [_shCamObj.sdk getAudioFormat];
    SHLogInfo(SHLogTagAPP, @"Codec:%x, freq: %d, chl: %d, bit:%d", format.getCodec(), format.getFrequency(), format.getNChannels(), format.getSampleBits());
    
    _pcmPl = [[PCMDataPlayer alloc] initWithFreq:format.getFrequency() channel:format.getNChannels() sampleBit:format.getSampleBits()];
    if (!_pcmPl) {
        SHLogError(SHLogTagAPP, @"Init audioQueue failed.");
        return;
    }
    
    while (_PVRun) {
        @autoreleasepool {
            if (_shCamObj.cameraProperty.isMute/*[_shCamObj.sdk isMute]*/) {
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
            
            [audioBuffer setLength:0];
            
            for (int i = 0; i < 1; i++) {
                SHAVData *audioData = [_shCamObj.sdk getAudioFrameData];
                
                if (audioData.data.length) {
                    [audioBuffer appendData:audioData.data];
                    if (audioBuffer.length >= MIN_SIZE_PER_FRAME) {
                        break;
                    }
                }
            }
            
            if (audioBuffer.length > 0 && _PVRun /*&& _enableDecoder*/) {
                [_pcmPl play:(void *)audioBuffer.bytes length:audioBuffer.length];
            }
        }
    }
    
    if (_pcmPl) {
        [_pcmPl stop];
    }
    _pcmPl = nil;
    
    SHLogInfo(SHLogTagAPP, @"quit audio");
}

- (int)play {
    _PVRun = YES;
    
    int retVal = [_shCamObj.sdk previewPlay];
    if (retVal != ICH_SUCCEED) {
        return retVal;
    };

    if ([_shCamObj.sdk audioStreamEnabled] && self.AudioRun) {
        dispatch_group_async(self.streamGroup, self.audioQueue, ^{[self playbackAudio1];});
    } else {
        self.AudioRun = NO;
        SHLogWarn(SHLogTagAPP, @"Streaming doesn't contains audio.");
    }
    
    if ([_shCamObj.sdk videoStreamEnabled]) {
        dispatch_group_async(self.streamGroup, self.videoQueue, ^{[self playbackVideo];});
    } else {
        SHLogWarn(SHLogTagAPP, @"Streaming doesn't contains video.");
    }
    
    return ICH_SUCCEED;
}

- (void)stopMediaStreamWithComplete:(void(^)())completeBlock {
    if (!_PVRun) {
        SHLogInfo(SHLogTagAPP, @"streaming already stopped.");
        return;
    }
    
    @synchronized (self) {
        _PVRun = NO;
    }
    
    [_shCamObj.sdk stopMediaStream];
    dispatch_group_notify(self.streamGroup, self.streamQ, ^{
        /*
        [_shCamObj.sdk removeObserver:self.streamObserver];
        delete self.streamObserver.listener;
        self.streamObserver.listener = NULL;
        self.streamObserver = nil;
         */
        self.enableDecoder = NO;
        
        dispatch_semaphore_signal(_shCamObj.semaphore);
    });
    
    if (!_PVRun) {
        if (completeBlock) {
            completeBlock();
        }
    }
}

- (void)stopPreview {
    @synchronized (self) {
        self.PVRun = NO;
        
        dispatch_semaphore_signal(_shCamObj.semaphore);
    }
}

- (BOOL)pause {
    return NO;
}

- (BOOL)resume {
    return NO;
}

- (BOOL)seek:(double)point {
    return NO;
}

- (void)isMute:(BOOL)mute successBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
    _shCamObj.cameraProperty.mute = !mute;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if(![_shCamObj.sdk openAudio: mute == 0 ? NO : YES]) {
            if (failedBlock) {
                failedBlock();
            }
            return;
        }
        
        if (successBlock) {
            successBlock();
        }
    });
}

- (void)openAudioServerWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ICatchAudioFormat *audioFormat = new ICatchAudioFormat();
		NSUserDefaults *defaultSettings = [NSUserDefaults standardUserDefaults];
		int audioRate = [defaultSettings integerForKey:@"PreferenceSpecifier:audioRate"];
        audioFormat->setCodec(ICATCH_CODEC_MPEG4_GENERIC);
        audioFormat->setFrequency(audioRate);
        audioFormat->setSampleBits(kBitsPerChannel);
        audioFormat->setNChannels(kChannelsPerFrame);
        
        if ([_shCamObj.sdk openAudioServer:*audioFormat]) {
            if (successBlock) {
                successBlock();
            }
        } else {
            if (failedBlock) {
                failedBlock();
            }
        }
    });
}

- (void)closeAudioServer {
    [_shCamObj.sdk closeAudioServer];
}

- (void)startTalkBackWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [_shCamObj.sdk setAECEnabled:NO];

//        NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
//        Config::getInstance()->openSaveAudio(path.UTF8String, "recvFile", "sendFile");
        if (_shCamObj.cameraProperty.serverOpened == NO) {
            [_shCamObj openAudioServer];
            
            if (_shCamObj.cameraProperty.serverOpened == NO) {
                if (failedBlock) {
                    failedBlock();
                }
                
                return;
            }
        }
        
        [self.audioUnitRecord startAudioUnit];

        __block BOOL ret;
        dispatch_sync(_shCamObj.sdk.sdkQueue, ^{
            SHLogTRACE();
            ret = [_shCamObj.sdk startSendAudioFrame];
            SHLogTRACE();
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
                [_shCamObj.streamOper isMute:NO successBlock:nil failedBlock:nil];
            }
        });

        if (ret) {

//            [self.audioUnit startAudioRecord];
//            [self.audioUnitRecord startAudioUnit];
            
            if (successBlock) {
                successBlock();
            }
        } else {
            [self.audioUnitRecord stopAudioUnit];

            if (failedBlock) {
                failedBlock();
            }
            
            return;
        }
    });
}

- (void)stopTalkBackWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        Config::getInstance()->closeSaveAudio();

//        [_pcmPl stopRecord];
//        [self.audioUnit stopAudioRecord];
        [self.audioUnitRecord stopAudioUnit];

        __block BOOL ret;
        dispatch_sync(_shCamObj.sdk.sdkQueue, ^{
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"]) {
                [_shCamObj.streamOper isMute:YES successBlock:nil failedBlock:nil];
            }
            
            SHLogTRACE();
            ret = [_shCamObj.sdk stopSendAvdioFrame:_shCamObj.cameraProperty.curAudioPts];
            SHLogTRACE();
        });
        
        if (ret) {
            if (successBlock) {
                successBlock();
            }
        } else {
            if (failedBlock) {
                failedBlock();
            }
        }
    });
}

- (BOOL)stopTalkBack {
    [self.audioUnitRecord stopAudioUnit];
    return [_shCamObj.sdk stopSendAvdioFrame:_shCamObj.cameraProperty.curAudioPts];
}

- (void)stillCaptureWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (self.currentVideoData.length > 0) {
            UIImage *currentImage = [self.h264Decoder imageFromPixelBufferRef:self.currentVideoData];
            
            if (currentImage != nil) {
                NSString *imagePath = [self createImagePath];
                
                if ([UIImageJPEGRepresentation(currentImage, 1.0) writeToFile:imagePath atomically:YES]) {
                    if (successBlock) {
                        successBlock();
                    }
                    
                    NSURL *fileURL = [NSURL fileURLWithPath:imagePath];
                    [[XJLocalAssetHelper sharedLocalAssetHelper] addNewAssetWithURL:fileURL toAlbum:kLocalAlbumName andFileType:ICH_FILE_TYPE_IMAGE forKey:_shCamObj.camera.cameraUid];
                } else {
                    if (failedBlock) {
                        failedBlock();
                    }
                }
                
            } else {
                if (failedBlock) {
                    failedBlock();
                }
            }
        } else {
            if (failedBlock) {
                failedBlock();
            }
        }
    });
}

- (NSString *)createImagePath {
    NSString *photoPath = [NSString stringWithFormat:@"%@", NSTemporaryDirectory()];
    
    time_t t = time(0);
    struct tm *time1 = localtime(&t);
    
    NSString *imageName = [NSString stringWithFormat:@"%d%02d%02d_%02d%02d%02d.JPG",  time1->tm_year + 1900,
                           time1->tm_mon + 1, time1->tm_mday, time1->tm_hour, time1->tm_min,
                           time1->tm_sec];
    
    NSString *fullPath = [NSString stringWithFormat:@"%@%@",photoPath, imageName];
    NSLog(@"Capture path: %@", fullPath);
    
    return fullPath;
}

/*********************** Write UIImage to local *************************/
- (void)writeImageDataToFile:(UIImage *)image andName:(NSString *)fileName {
    // Create paths to output images
    NSString  *pngPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.png" , fileName]];
    //NSString  *jpgPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.jpg", fileName]];
    
    // Write a UIImage to JPEG with minimum compression (best quality)
    // The value 'image' must be a UIImage object
    // The value '1.0' represents image compression quality as value from 0.0 to 1.0
    //[UIImageJPEGRepresentation(image, 1.0) writeToFile:jpgPath atomically:YES];
    
    // Write image to PNG
    [UIImagePNGRepresentation(image) writeToFile:pngPath atomically:YES];
    
    // Let's check to see if files were successfully written...
    
    // Create file manager
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    // Point to Document directory
    NSString *documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    
    // Write out the contents of home directory to console
    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}

@end
