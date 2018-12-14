//
//  PCMDataPlayer.h
//  PCMDataPlayerDemo
//
//  Created by Android88 on 15-2-10.
//  Copyright (c) 2015年 Android88. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

// playback
#define QUEUE_BUFFER_SIZE 6 //队列缓冲个数
#define MIN_SIZE_PER_FRAME 4096 //每帧最小数据长度

//record
#define kNumberBuffers      3
#define kFrameSize          4096
#define kSampleRate         16000
#define kChannelsPerFrame   1
#define kBitsPerChannel     16

@interface PCMDataPlayer : NSObject {
    AudioStreamBasicDescription audioDescription; ///音频参数
    AudioQueueRef audioQueue; //音频播放队列
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE]; //音频缓存
    BOOL audioQueueUsed[QUEUE_BUFFER_SIZE];

    NSLock* sysnLock;

    // record
    AudioQueueRef           inputQueue;
    AudioQueueBufferRef     inputBuffers[kNumberBuffers];
    Byte audioByte[kFrameSize];
    FILE *file;
}

- (id)initWithFreq:(Float64)freq channel:(UInt32)channel sampleBit:(UInt32)bit;
/*!
 *  @author 15-02-10 16:02:27
 *
 *  @brief  重置播放器
 *
 *  @since v1.0
 */
- (void)reset;

/*!
 *  @author 15-02-10 17:02:52
 *
 *  @brief  停止播放
 *
 *  @since v1.0
 */
- (void)stop;

/*!
 *  @author 15-02-10 16:02:56
 *
 *  @brief  播放PCM数据
 *
 *  @param pcmData pcm字节数据
 *
 *  @since v1.0
 */
- (void)play:(void*)pcmData length:(NSUInteger)length;

@property (nonatomic, assign) long audioDataLength;
@property (nonatomic, assign) double audioPts;

- (void) start;
- (void)stopRecord;
- (Byte *)getBytes;

@property (nonatomic, weak) SHCameraObject *shCameraObj;
@property (nonatomic, assign) long audioDataCurLength;

@end
