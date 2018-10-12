//
//  SHAudioUnitRecord.m
//  SmartHome
//
//  Created by ZJ on 2017/11/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHAudioUnitRecord.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>

#define INPUT_BUS 1
#define OUTPUT_BUS 0
#define CONST_BUFFER_SIZE 2048*2*10

#define startTag 10
#define stopTag 20

#define kFrameSize          2048
#define kSampleRate         48000
#define kChannelsPerFrame   1
#define kBitsPerChannel     16

@interface SHAudioUnitRecord () {
    AudioUnit audioUnit;
    AudioBufferList *buffList;
    
    //    NSInputStream *inputSteam;
    //    Byte *buffer;
    
    UInt32 audioDataLength;
    UInt32 audioDataCurLength;
    Byte audioByte[kFrameSize];
    double audioPts;
}

@property (nonatomic, weak) SHCameraObject *shCameraObj;
@property (nonatomic, assign) NSInteger currentRate;

@end

@implementation SHAudioUnitRecord

- (instancetype)initWithCameraObj:(SHCameraObject *)obj
{
    self = [super init];
    if (self) {
        self.shCameraObj = obj;
    }
    return self;
}

- (void)startAudioUnit {
    [ self initAudioUnit];
//    AudioOutputUnitStart(audioUnit);
}

- (void)stopAudioUnit {
    if (audioUnit != nil) {
        AudioOutputUnitStop(audioUnit);
        AudioUnitUninitialize(audioUnit);
        
        AudioComponentInstanceDispose(audioUnit);
        
        audioUnit = nil;
    }
    
//    free(buffList->mBuffers);
//    buffList = NULL;
//    free(audioByte);
//    audioDataLength = 0;
//    audioDataCurLength = 0;
//    audioPts = 0.0;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
}

- (void)initAudioUnit {
    NSError *error = nil;
    OSStatus status = noErr;
    
    // audio session
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
//    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    if (error) {
        NSLog(@"setCategory error:%@", error);
    }
    [[AVAudioSession sharedInstance] setPreferredIOBufferDuration:0.05 error:&error];
    if (error) {
        NSLog(@"setPreferredIOBufferDuration error:%@", error);
    }
    // buffer list
    uint32_t numberBuffers = 1;
    buffList = (AudioBufferList *)malloc(sizeof(AudioBufferList) + (numberBuffers - 1) * sizeof(AudioBuffer));
    buffList->mNumberBuffers = numberBuffers;
    buffList->mBuffers[0].mNumberChannels = 1;
    buffList->mBuffers[0].mDataByteSize = CONST_BUFFER_SIZE;
    buffList->mBuffers[0].mData = malloc(CONST_BUFFER_SIZE);
    
    for (int i =1; i < numberBuffers; ++i) {
        buffList->mBuffers[i].mNumberChannels = 1;
        buffList->mBuffers[i].mDataByteSize = CONST_BUFFER_SIZE;
        buffList->mBuffers[i].mData = malloc(CONST_BUFFER_SIZE);
    }
    
//    buffer = (Byte *)malloc(CONST_BUFFER_SIZE);
    // audio unit new
    AudioComponentDescription audioDesc;
    audioDesc.componentType = kAudioUnitType_Output;
    audioDesc.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    audioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    audioDesc.componentFlags = 0;
    audioDesc.componentFlagsMask = 0;
    AudioComponent inputComponent = AudioComponentFindNext(NULL, &audioDesc);
    status = AudioComponentInstanceNew(inputComponent, &audioUnit);
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    // set format
    AudioStreamBasicDescription inputFormat;
    inputFormat.mSampleRate = kSampleRate;
    inputFormat.mFormatID = kAudioFormatLinearPCM;
    inputFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;//kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    inputFormat.mFramesPerPacket = 1;
    inputFormat.mChannelsPerFrame = 1;
    inputFormat.mBytesPerPacket = 2;
    inputFormat.mBytesPerFrame = 2;
    inputFormat.mBitsPerChannel = 16;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioUnitProperty_StreamFormat,
                                  kAudioUnitScope_Output,
                                  INPUT_BUS,
                                  &inputFormat,
                                  sizeof(inputFormat));
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    // enable record
    UInt32 flag = 1;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_EnableIO,
                                  kAudioUnitScope_Input,
                                  INPUT_BUS,
                                  &flag,
                                  sizeof(flag));
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    // set callback
    AURenderCallbackStruct recordCallback;
    recordCallback.inputProc = RecordCallback;
    recordCallback.inputProcRefCon = (__bridge void *)self;
    status = AudioUnitSetProperty(audioUnit,
                                  kAudioOutputUnitProperty_SetInputCallback,
                                  kAudioUnitScope_Output,
                                  INPUT_BUS,
                                  &recordCallback,
                                  sizeof(recordCallback));
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    OSStatus result = AudioUnitInitialize(audioUnit);
    NSLog(@"result %d", result);
    
    AudioOutputUnitStart(audioUnit);

    [[AVAudioSession sharedInstance] setPreferredSampleRate:inputFormat.mSampleRate error:&error];
    if (error) NSLog(@"ERROR SETTING SESSION SAMPLE RATE! %ld", (long)error.code);
    
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) NSLog(@"ERROR SETTING SESSION ACTIVE! %ld", (long)error.code);
    
    [self openOrCloseEchoCancellation:0];
    
    _currentRate = [[NSUserDefaults standardUserDefaults] integerForKey:@"PreferenceSpecifier:audioRate"];
    _shCameraObj.cameraProperty.curAudioPts = 0.0;
    audioPts = 0.0;
}

- (void)openOrCloseEchoCancellation:(UInt32)isAEC {
    OSStatus status = noErr;

    UInt32 echoCancellation;
    UInt32 size = sizeof(echoCancellation);
    status = AudioUnitGetProperty(audioUnit,
                        kAUVoiceIOProperty_BypassVoiceProcessing,
                        kAudioUnitScope_Global,
                        0,
                        &echoCancellation,
                        &size);
    
    if (status != noErr) {
        NSLog(@"AudioUnitGetProperty error, ret: %d", status);
    }
    
    if (echoCancellation == isAEC) {
        NSLog(@"AEC is opened.");
    } else {
        echoCancellation = isAEC;
        
        status = AudioUnitSetProperty(audioUnit,
                                      kAUVoiceIOProperty_BypassVoiceProcessing,
                                      kAudioUnitScope_Global,
                                      0,
                                      &echoCancellation,
                                      sizeof(echoCancellation));
        if (status != noErr) {
            NSLog(@"AudioUnitGetProperty error, ret: %d", status);
        }
    }
}

#pragma mark - callback

static OSStatus RecordCallback(void *inRefCon,
                               AudioUnitRenderActionFlags *ioActionFlags,
                               const AudioTimeStamp *inTimeStamp,
                               UInt32 inBusNumber,
                               UInt32 inNumberFrames,
                               AudioBufferList *ioData)
{
    SHAudioUnitRecord *vc = (__bridge SHAudioUnitRecord *)inRefCon;
    if ([vc isPlay]) {
        return noErr;
    }
    
    if (!vc.shCameraObj.cameraProperty.isTalk) {
        return noErr;
    }
    
    vc->buffList->mNumberBuffers = 1;
    OSStatus status = AudioUnitRender(vc->audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, vc->buffList);
    if (status != noErr) {
        NSLog(@"AudioUnitRender error:%d", status);
    }
    
    // NSLog(@"size1 = %d", vc->buffList->mBuffers[0].mDataByteSize);
    [vc writePCMData:(Byte *)vc->buffList->mBuffers[0].mData size:vc->buffList->mBuffers[0].mDataByteSize];
    
    return noErr;
}

- (BOOL)isPlay {
    return ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"] && !_shCameraObj.cameraProperty.isMute);
}

- (void)writePCMData:(Byte *)buffer size:(int)size {
    audioDataLength = size;
//    if (_shCameraObj.streamOper.isBuffering) {
//        return;
//    }
    
    char outputBuffer[kFrameSize] = {0};
    int ret = [_shCameraObj.sdk resamplerWithInputBuffer:(char *)buffer inputSize:audioDataLength outputBuffer:outputBuffer outputSize:kFrameSize];
    if (ret < 0) {
        NSLog(@"resample error!!");
        return;
    } else {
        audioDataLength = ret;
    }
//    NSLog(@"resample audioDataLength = %ld",audioDataLength);
    
    if (audioDataCurLength) {
        UInt32 dValue = kFrameSize - audioDataCurLength;
        if (dValue > audioDataLength) {
            memcpy(audioByte + audioDataCurLength , outputBuffer, audioDataLength);
            audioDataCurLength += audioDataLength;
        } else {
            UInt32 res = audioDataLength - dValue;
            memcpy(audioByte + audioDataCurLength , outputBuffer, dValue);
            
            ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
            memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
            audioFrameBuffer->setFrameSize(kFrameSize);
            audioFrameBuffer->setPresentationTime(audioPts);
            
            [_shCameraObj.sdk sendAudioFrame:audioFrameBuffer andDB:0];
            audioPts += kFrameSize / (kChannelsPerFrame * kBitsPerChannel * 0.125 * _currentRate);
            _shCameraObj.cameraProperty.curAudioPts = audioPts;

            delete audioFrameBuffer;
            audioFrameBuffer = NULL;
            memset(audioByte, 0, sizeof(audioByte));
            
            memcpy(audioByte , (unsigned char *)(outputBuffer) + dValue , res);
            audioDataCurLength = res;
        }
    } else {
        if (audioDataLength < kFrameSize) {
            memcpy(audioByte, outputBuffer, audioDataLength);
            audioDataCurLength = audioDataLength;
        } else {
            memcpy(audioByte, outputBuffer, audioDataLength);

            ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
            memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
            audioFrameBuffer->setFrameSize(kFrameSize);
            audioFrameBuffer->setPresentationTime(audioPts);
            
            [_shCameraObj.sdk sendAudioFrame:audioFrameBuffer andDB:0];
            audioPts += kFrameSize / (kChannelsPerFrame * kBitsPerChannel * 0.125 * _currentRate);
            _shCameraObj.cameraProperty.curAudioPts = audioPts;

            delete audioFrameBuffer;
            audioFrameBuffer = NULL;
            memset(audioByte, 0, sizeof(audioByte));
        }
    }
}

@end
