//
//  PCMDataPlayer.m
//  PCMDataPlayerDemo
//
//  Created by Android88 on 15-2-10.
//  Copyright (c) 2015年 Android88. All rights reserved.
//

#import "PCMDataPlayer.h"

@interface PCMDataPlayer()

@property(nonatomic) Float64 freq;
@property(nonatomic) UInt32 channel;
@property(nonatomic) UInt32 bit;

@end

@implementation PCMDataPlayer

- (id)initWithFreq:(Float64)freq channel:(UInt32)channel sampleBit:(UInt32)bit
{
    self = [super init];
    if (self) {
        self.freq = freq;
        self.channel = channel;
        self.bit = bit;
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
    }
    audioQueue = nil;

    sysnLock = nil;

    NSLog(@"PCMDataPlayer dealloc...");
    [self resetAudioSession];
}

static void AQInputCallback (void                   * inUserData,
                             AudioQueueRef          inAudioQueue,
                             AudioQueueBufferRef    inBuffer,
                             const AudioTimeStamp   * inStartTime,
                             unsigned long          inNumPackets,
                             const AudioStreamPacketDescription * inPacketDesc)
{
    @autoreleasepool {
        PCMDataPlayer * engine = (__bridge PCMDataPlayer *) inUserData;
        if (inNumPackets > 0)
        {
            [engine processAudioBuffer:inBuffer withQueue:inAudioQueue];
        }
        
        AudioQueueEnqueueBuffer(inAudioQueue, inBuffer, 0, NULL);
    }
}

- (Byte *)getBytes
{
    return audioByte;
}

- (void) start
{
    AudioStreamBasicDescription inputAudioFormat; ///音频参数
    ///设置音频参数
    inputAudioFormat.mSampleRate = kSampleRate; //采样率
    inputAudioFormat.mFormatID = kAudioFormatLinearPCM;
    inputAudioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    inputAudioFormat.mChannelsPerFrame = kChannelsPerFrame; ///单声道
    inputAudioFormat.mFramesPerPacket = 1; //每一个packet一侦数据
    inputAudioFormat.mBitsPerChannel = kBitsPerChannel; //每个采样点16bit量化
    inputAudioFormat.mBytesPerFrame = (inputAudioFormat.mBitsPerChannel / 8) * inputAudioFormat.mChannelsPerFrame;
    inputAudioFormat.mBytesPerPacket = inputAudioFormat.mBytesPerFrame;
    
    //创建一个录制音频队列
    AudioQueueNewInput (&(inputAudioFormat),(AudioQueueInputCallback)AQInputCallback,(__bridge void *)self,NULL,kCFRunLoopCommonModes,0,&inputQueue);
    
    for (int i=0;i<kNumberBuffers;i++)
    {
        AudioQueueAllocateBuffer(inputQueue, kFrameSize, &inputBuffers[i]);
        AudioQueueEnqueueBuffer(inputQueue, inputBuffers[i], 0, NULL);
    }
    
    AudioQueueStart(inputQueue, NULL);
    
//    [self writeAudioDataToFileForTest];
}

- (void)writeAudioDataToFileForTest {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *mediaDirectory = [documentsDirectory stringByAppendingPathComponent:@"Audio"];
        [[NSFileManager defaultManager] createDirectoryAtPath:mediaDirectory withIntermediateDirectories:NO attributes:nil error:nil];
        NSString *filePath = [mediaDirectory stringByAppendingPathComponent:@"record.pcm"];
        file = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "a+");

//        [[SHSDK sharedSHSDK] setSaveAudioPath:mediaDirectory.UTF8String];
    });
}

- (void)stopRecord {
    if (inputQueue != nil) {
        AudioQueueStop(inputQueue, true);
        AudioQueueReset(inputQueue);
    }
    
    inputQueue = nil;
}

- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue
{
    NSLog(@"processAudioData :%zd", buffer->mAudioDataByteSize);
    //处理data：忘记oc怎么copy内存了，于是采用的C++代码，记得把类后缀改为.mm。同Play
    _audioDataLength = buffer->mAudioDataByteSize;
    
    if (_audioDataCurLength) {
        long dValue = kFrameSize - _audioDataCurLength;
        if (dValue > _audioDataLength) {
            memcpy(audioByte + _audioDataCurLength , buffer->mAudioData, _audioDataLength);
            _audioDataCurLength += _audioDataLength;
        } else {
            long res = _audioDataLength - dValue;
            memcpy(audioByte + _audioDataCurLength , buffer->mAudioData, dValue);

            [self sendAudioFrameData];
            
            memcpy(audioByte , (unsigned char *)(buffer->mAudioData) + dValue , res);
            _audioDataCurLength = res;
        }
    } else {
        if (_audioDataLength < kFrameSize) {
            memcpy(audioByte, buffer->mAudioData, _audioDataLength);
            _audioDataCurLength = _audioDataLength;
        } else {
            memcpy(audioByte, buffer->mAudioData, _audioDataLength);
            [self sendAudioFrameData];
        }
    }

//    NSLog(@"processAudioData :%zd", buffer->mAudioDataByteSize);
//    //处理data：忘记oc怎么copy内存了，于是采用的C++代码，记得把类后缀改为.mm。同Play
//    memcpy(audioByte, buffer->mAudioData, buffer->mAudioDataByteSize);
//    _audioDataLength = buffer->mAudioDataByteSize;
////    fwrite(buffer->mAudioData, sizeof(char), buffer->mAudioDataByteSize, file);
//    
//    _audioPts += [self calcAudioPTS:_audioDataLength];
//    SHLogInfo(SHLogTagAPP, @"audioPTS: %f", _audioPts);
////    ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer((unsigned char *)buffer->mAudioData, (int)_audioDataLength);
//
//    ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(1024 * 10);
//    
//    memcpy(audioFrameBuffer->getBuffer(), (unsigned char *)buffer->mAudioData, _audioDataLength);
//    audioFrameBuffer->setFrameSize((int)_audioDataLength);
//    audioFrameBuffer->setPresentationTime(_audioPts);
//    
//    [_shCameraObj.sdk sendAudioFrame:audioFrameBuffer andDB:[self calcAudioDB:audioByte]];
//    delete audioFrameBuffer;
//    audioFrameBuffer = NULL;
}

- (void)sendAudioFrameData {
    _audioPts += [self calcAudioPTS:kFrameSize];
    SHLogInfo(SHLogTagAPP, @"audioPTS: %f", _audioPts);
    
    ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
    
    memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
    audioFrameBuffer->setFrameSize(kFrameSize);
    audioFrameBuffer->setPresentationTime(_audioPts);
    
    [_shCameraObj.sdk sendAudioFrame:audioFrameBuffer andDB:[self calcAudioDB:audioByte]];
    delete audioFrameBuffer;
    audioFrameBuffer = NULL;
}

- (double)calcAudioPTS:(long)audioLength {
    return audioLength / (kChannelsPerFrame * kBitsPerChannel * 0.125 * kSampleRate);
}

- (double)calcAudioDB:(Byte *)byte {
    int length = (int)(kFrameSize * 0.5);
    short dest[length];
    long v = 0;

    for (int i = 0; i < length; i++) {
        dest[i] = (short) (byte[i * 2] << 8 | (byte[2 * i + 1] & 0xff));
        v += dest[i] * dest[i];
    }

    double mean = v / length;
    double volume = 10 * log10(mean);
    SHLogInfo(SHLogTagAPP, @"DB: %f", volume);
    
    return volume;
}

static void AudioPlayerAQInputCallback(void* inUserData, AudioQueueRef outQ, AudioQueueBufferRef outQB)
{
    PCMDataPlayer* player = (__bridge PCMDataPlayer*)inUserData;
    [player playerCallback:outQB];
}

- (void)reset
{
    [self stop];

    sysnLock = [[NSLock alloc] init];

    ///设置音频参数
    audioDescription.mSampleRate = self.freq; //采样率
    audioDescription.mFormatID = kAudioFormatLinearPCM;
    audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    audioDescription.mChannelsPerFrame = self.channel; ///单声道
    audioDescription.mFramesPerPacket = 1; //每一个packet一侦数据
    audioDescription.mBitsPerChannel = self.bit; //每个采样点16bit量化
    audioDescription.mBytesPerFrame = (audioDescription.mBitsPerChannel / 8) * audioDescription.mChannelsPerFrame;
    audioDescription.mBytesPerPacket = audioDescription.mBytesPerFrame;

    AudioQueueNewOutput(&audioDescription, AudioPlayerAQInputCallback, (__bridge void*)self, nil, nil, 0, &audioQueue); //使用player的内部线程播放

    //设置话筒属性等
//    [self initSession];
//
//    NSError *error = nil;
//    //设置audioSession格式 录音播放模式
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
//
//    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;  //设置成话筒模式
//    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
//                             sizeof (audioRouteOverride),
//                             &audioRouteOverride);
#if 0
    NSError *err = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setActive:NO error:&err];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&err];
    [audioSession setActive:YES error:&err];
#else
    [self setAudioSession];
#endif
    //初始化音频缓冲区
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        int result = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]); ///创建buffer区，MIN_SIZE_PER_FRAME为每一侦所需要的最小的大小，该大小应该比每次往buffer里写的最大的一次还大
        NSLog(@"AudioQueueAllocateBuffer i = %d,result = %d", i, result);
    }

    NSLog(@"PCMDataPlayer reset");
    
    AudioQueueStart(audioQueue, NULL);
}

- (void)setAudioSession {
    //设置AVAudioSession
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    
    SHLogInfo(SHLogTagAPP, @"Current category: %@, options: %lu, mode: %@", session.category, (unsigned long)session.categoryOptions, session.mode);

    [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth error:&error];
    if (error != nil) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
    }
    
    [session setActive:YES error:&error];
    if (error != nil) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
    }
}

- (void)resetAudioSession {
    NSError *error = nil;
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    [audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (error != nil) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
    }
}

//初始化会话
- (void)initSession
{
    UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;         //可在后台播放声音
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;  //设置成话筒模式
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,
                             sizeof (audioRouteOverride),
                             &audioRouteOverride);
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    //默认情况下扬声器播放
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
}

- (void)stop
{
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue, true);
        AudioQueueReset(audioQueue);
    }

    audioQueue = nil;
}

- (void)play:(void*)pcmData length:(NSUInteger)length
{
    if (audioQueue == nil || ![self checkBufferHasUsed]) {
//        [self reset];
//        AudioQueueStart(audioQueue, NULL);
        AudioQueueReset(audioQueue);
    }

    [sysnLock lock];

    AudioQueueBufferRef audioQueueBuffer = NULL;

    while (true) {
        @autoreleasepool {
            audioQueueBuffer = [self getNotUsedBuffer];
            if (audioQueueBuffer != NULL) {
                break;
            } else {
                [NSThread sleepForTimeInterval:0.002];
                AudioQueueStart(audioQueue, NULL);
            }
        }
    }

    audioQueueBuffer->mAudioDataByteSize = (uint)length;
    Byte* audiodata = (Byte*)audioQueueBuffer->mAudioData;
//    memcpy(audiodata, pcmData, length);
    for (int i = 0; i < length; i++) {
        audiodata[i] = ((Byte*)pcmData)[i];
    }

    AudioQueueEnqueueBuffer(audioQueue, audioQueueBuffer, 0, NULL);

    //SHLogDebug(SHLogTagAPP, @"PCMDataPlayer play dataSize:%d", length);

    [sysnLock unlock];
}

- (BOOL)checkBufferHasUsed
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (YES == audioQueueUsed[i]) {
            return YES;
        }
    }
    NSLog(@"PCMDataPlayer 播放中断............");
    return NO;
}

- (AudioQueueBufferRef)getNotUsedBuffer
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (NO == audioQueueUsed[i]) {
            audioQueueUsed[i] = YES;
//            SHLogDebug(SHLogTagAPP, @"PCMDataPlayer play buffer index:%d", i);
            return audioQueueBuffers[i];
        }
    }
    return NULL;
}

- (void)playerCallback:(AudioQueueBufferRef)outQB
{
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        if (outQB == audioQueueBuffers[i]) {
            audioQueueUsed[i] = NO;
        }
    }
}

@end
