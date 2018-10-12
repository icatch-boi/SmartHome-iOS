//
//  SHAudioUnit.m
//  SmartHome
//
//  Created by ZJ on 2017/8/28.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHAudioUnit.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef struct MyAUGraphStruct{
    AUGraph graph;
    AudioUnit remoteIOUnit;
} MyAUGraphStruct;

#define kFrameSize          2048
#define kSampleRate         44100
#define kChannelsPerFrame   1
#define kBitsPerChannel     16

NSFileHandle *fileHandle;
NSString *destinationPath;
@interface SHAudioUnit ()

@property (nonatomic,assign)AudioStreamBasicDescription streamFormat;

@end

@implementation SHAudioUnit

@synthesize streamFormat;
MyAUGraphStruct myStruct;

AudioBuffer recordedBuffers[kFrameSize];//Used to save audio data
int         currentBufferPointer;//Pointer to the current buffer
int         callbackCount;
UInt32 audioDataLength;
UInt32 audioDataCurLength;
Byte audioByte[kFrameSize];
double audioPts;
SHCameraObject *obj;

- (void)setShCameraObj:(SHCameraObject *)shCameraObj {
    obj = shCameraObj;
}

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

OSStatus InputCallback(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *ioData){
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"PreferenceSpecifier:PushToTalk"] && !obj.cameraProperty.isMute) {
        return noErr;
    }
    //TODO: implement this function
    MyAUGraphStruct* myStruct = (MyAUGraphStruct*)inRefCon;
    
    //Get samples from input bus(bus 1)
    CheckError(AudioUnitRender(myStruct->remoteIOUnit,
                               ioActionFlags,
                               inTimeStamp,
                               1,
                               inNumberFrames,
                               ioData),
               "AudioUnitRender failed");
//
//    //save audio to ring buffer and load from ring buffer
//    AudioBuffer buffer = ioData->mBuffers[0];
//    recordedBuffers[currentBufferPointer].mNumberChannels = buffer.mNumberChannels;
//    recordedBuffers[currentBufferPointer].mDataByteSize = buffer.mDataByteSize;
//    free(recordedBuffers[currentBufferPointer].mData);
//    recordedBuffers[currentBufferPointer].mData = malloc(sizeof(SInt16)*buffer.mDataByteSize);
//    memcpy(recordedBuffers[currentBufferPointer].mData,
//           buffer.mData,
//           buffer.mDataByteSize);
//    currentBufferPointer = (currentBufferPointer+1)%kFrameSize;
//
//    if (callbackCount>=kFrameSize) {
//        memcpy(buffer.mData,
//               recordedBuffers[currentBufferPointer].mData,
//               buffer.mDataByteSize);
//    }
//    callbackCount++;
    AudioBuffer buffer = ioData->mBuffers[0];
    audioDataLength = buffer.mDataByteSize;
//    NSLog(@"processAudioData :%zd", audioDataLength);

    if (obj.streamOper.isBuffering) {
        return noErr;
    }
    
    audioPts += audioDataLength / (kChannelsPerFrame * kBitsPerChannel * 0.125 * kSampleRate);
   // SHLogDebug(SHLogTagAPP, @"audioPTS: %f", audioPts);
    
	
#if 0
	NSData *data = [NSData dataWithBytes:buffer.mData length:buffer.mDataByteSize];
	if(fileHandle != nil){
		//NSLog(@"writeData to file");
		[fileHandle writeData:data]; //写入
		NSFileManager *fm=[NSFileManager defaultManager];
		NSDictionary *fileAttr = [fm attributesOfItemAtPath:destinationPath error:NULL];
		if(fileAttr!=nil){
			//			NSLog(@"文件大小:%llu bytes",[[fileAttr objectForKey:NSFileSize] unsignedLongLongValue]);
		}
		//return noErr;
	}else{
		NSDate *date=[NSDate date];//获取当前时间
		NSDateFormatter *format1=[[NSDateFormatter alloc]init];
		[format1 setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
		NSString *dateStr1=[format1 stringFromDate:date];
		
		//	NSString *dateStr1=@"111111";
		NSString *fileName = [dateStr1 stringByAppendingString:@".record"];
		
		NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		destinationPath = [documentsPath stringByAppendingPathComponent:fileName];
		NSFileManager *fileManger=[NSFileManager defaultManager];
		Boolean isSuccess = NO;
		//如果路径不存在则创建
		if(![fileManger fileExistsAtPath:destinationPath])
		{
			isSuccess=[fileManger createFileAtPath:destinationPath contents:nil attributes:nil];
		}
		if(isSuccess)
		{
			NSLog(@"文件创建成功！");
		}
		
		//  //取文件所在的目录
		//
		fileHandle=[NSFileHandle fileHandleForUpdatingAtPath:destinationPath];
		[fileHandle writeData:data]; //写入
	}
#endif
	
	char outputBuffer[kFrameSize] = {};
	int ret = [obj.sdk resamplerWithInputBuffer:(char *)buffer.mData inputSize:audioDataLength outputBuffer:outputBuffer outputSize:kFrameSize];
    if (ret < 0) {
		NSLog(@"resample error!!");
        return noErr;
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
            
//            [self sendAudioFrameData];
//            audioPts += kFrameSize / (kChannelsPerFrame * kBitsPerChannel * 0.125 * kSampleRate);
//            SHLogInfo(SHLogTagAPP, @"audioPTS: %f", audioPts);
            
            ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
            memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
            audioFrameBuffer->setFrameSize(kFrameSize);
            audioFrameBuffer->setPresentationTime(audioPts);
            obj.cameraProperty.curAudioPts = audioPts;
			
            [obj.sdk sendAudioFrame:audioFrameBuffer andDB:0];
       
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
//            [self sendAudioFrameData];
//            audioPts += kFrameSize / (kChannelsPerFrame * kBitsPerChannel * 0.125 * kSampleRate);
//            SHLogInfo(SHLogTagAPP, @"audioPTS: %f", audioPts);
            
            ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
            memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
            audioFrameBuffer->setFrameSize(kFrameSize);
            audioFrameBuffer->setPresentationTime(audioPts);
            obj.cameraProperty.curAudioPts = audioPts;

            [obj.sdk sendAudioFrame:audioFrameBuffer andDB:0];
            
            delete audioFrameBuffer;
            audioFrameBuffer = NULL;
            memset(audioByte, 0, sizeof(audioByte));
        }
    }
    
    return noErr;
}

- (void)sendAudioFrameData {
    audioPts += [self calcAudioPTS:kFrameSize];
    SHLogInfo(SHLogTagAPP, @"audioPTS: %f", audioPts);
    
    ICatchFrameBuffer *audioFrameBuffer = new ICatchFrameBuffer(AUDIO_BUFFER_SIZE);
    
    memcpy(audioFrameBuffer->getBuffer(), audioByte, kFrameSize);
    audioFrameBuffer->setFrameSize(kFrameSize);
    audioFrameBuffer->setPresentationTime(audioPts);
    
    [_shCameraObj.sdk sendAudioFrame:audioFrameBuffer andDB:0];
    delete audioFrameBuffer;
    audioFrameBuffer = NULL;
}

- (double)calcAudioPTS:(long)audioLength {
    return audioLength / (kChannelsPerFrame * kBitsPerChannel * 0.125 * kSampleRate);
}

- (void)startAudioRecord {
    //Initialize currentBufferPointer
//    NSError *error;
//    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
//    if (error) {
//        NSLog(@"AVAudioSessionCategoryPlayAndRecord failed %@",error);
//    }
    currentBufferPointer = 0;
    callbackCount = 0;
    //SHLogTRACE();
    //[self setupSession];
    SHLogTRACE();
    [self createAUGraph:&myStruct];
    SHLogTRACE();
    [self setupRemoteIOUnit:&myStruct];
    SHLogTRACE();
    [self startGraph:myStruct.graph];
    SHLogTRACE();
    // 0 open AEC
    [self openOrCloseEchoCancellation:0];
    SHLogTRACE();
    [self setupSession];
}

- (void)stopAudioRecord {
    if (myStruct.remoteIOUnit != nil) {
        AudioOutputUnitStop(myStruct.remoteIOUnit);
        myStruct.remoteIOUnit = nil;
    }
    
    if (myStruct.graph != nil) {
        [self stopGraph:myStruct.graph];
        myStruct.graph = nil;
    }
	if(fileHandle != nil){
		[fileHandle closeFile];
		fileHandle = nil;
	}
}

- (void)openOrCloseEchoCancellation:(UInt32)isAEC {
    UInt32 echoCancellation;
    UInt32 size = sizeof(echoCancellation);
    CheckError(AudioUnitGetProperty(myStruct.remoteIOUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Global,
                                    0,
                                    &echoCancellation,
                                    &size),
               "kAUVoiceIOProperty_BypassVoiceProcessing failed");
    if (echoCancellation == isAEC) {
        return;
    } else {
        echoCancellation = isAEC;
    }
    
    CheckError(AudioUnitSetProperty(myStruct.remoteIOUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Global,
                                    0,
                                    &echoCancellation,
                                    sizeof(echoCancellation)),
               "AudioUnitSetProperty kAUVoiceIOProperty_BypassVoiceProcessing failed");
    
//    [button setTitle:echoCancellation==0?@"Echo cancellation is open":@"Echo cancellation is closed" forState:UIControlStateNormal];
}

- (void)startGraph:(AUGraph)graph{
    CheckError(AUGraphInitialize(graph),
               "AUGraphInitialize failed");
    
    CheckError(AUGraphStart(graph),
               "AUGraphStart failed");
}

- (void)stopGraph:(AUGraph)graph {
    CheckError(AUGraphStop(graph), "AUGraphStop failed");
    CheckError(AUGraphUninitialize(graph), "AUGraphUninitialize");
    CheckError(AUGraphClose(graph), "AUGraphClose");
}

- (void)setupRemoteIOUnit:(MyAUGraphStruct*)myStruct {
    //Open input of the bus 1(input mic)
    UInt32 enableFlag = 1;
    CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &enableFlag,
                                    sizeof(enableFlag)),
               "Open input of bus 1 failed");
    
    //    //Open output of bus 0(output speaker)
    //    CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
    //                                    kAudioOutputUnitProperty_EnableIO,
    //                                    kAudioUnitScope_Output,
    //                                    0,
    //                                    &enableFlag,
    //                                    sizeof(enableFlag)),
    //               "Open output of bus 0 failed");
    
    //Set up stream format for input and output
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamFormat.mSampleRate = 44100;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 2;
    streamFormat.mBytesPerPacket = 2;
    streamFormat.mBitsPerChannel = 16;
    streamFormat.mChannelsPerFrame = 1;
//    streamFormat.mFormatID = kAudioFormatLinearPCM;
//    streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
//    streamFormat.mSampleRate = 44100;
//    streamFormat.mFramesPerPacket = 1;
//    streamFormat.mBytesPerFrame = (streamFormat.mBitsPerChannel / 8) * streamFormat.mChannelsPerFrame;
//    streamFormat.mBytesPerPacket = streamFormat.mBytesPerFrame;
//    streamFormat.mBitsPerChannel = kBitsPerChannel;
//    streamFormat.mChannelsPerFrame = kChannelsPerFrame;
    
    //    CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
    //                                    kAudioUnitProperty_StreamFormat,
    //                                    kAudioUnitScope_Input,
    //                                    0,
    //                                    &streamFormat,
    //                                    sizeof(streamFormat)),
    //               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    
    CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &streamFormat,
                                    sizeof(streamFormat)),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    //Set up input callback
    AURenderCallbackStruct input;
    input.inputProc = InputCallback;
    input.inputProcRefCon = myStruct;
    CheckError(AudioUnitSetProperty(myStruct->remoteIOUnit,
                                    kAudioUnitProperty_SetRenderCallback,
                                    kAudioUnitScope_Global,
                                    0,//input mic
                                    &input,
                                    sizeof(input)),
               "kAudioUnitProperty_SetRenderCallback failed");
}

- (void)createAUGraph:(MyAUGraphStruct*)myStruct {
    //Create graph
    CheckError(NewAUGraph(&myStruct->graph),
               "NewAUGraph failed");
    
    //Create nodes and add to the graph
    //Set up a RemoteIO for synchronously playback
    AudioComponentDescription inputcd = {0};
    inputcd.componentType = kAudioUnitType_Output;
    //inputcd.componentSubType = kAudioUnitSubType_RemoteIO;
    //we can access the system's echo cancellation by using kAudioUnitSubType_VoiceProcessingIO subtype
    inputcd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUNode remoteIONode;
    //Add node to the graph
    CheckError(AUGraphAddNode(myStruct->graph,
                              &inputcd,
                              &remoteIONode),
               "AUGraphAddNode failed");
    
    //Open the graph
    CheckError(AUGraphOpen(myStruct->graph),
               "AUGraphOpen failed");
    
    //Get reference to the node
    CheckError(AUGraphNodeInfo(myStruct->graph,
                               remoteIONode,
                               &inputcd,
                               &myStruct->remoteIOUnit),
               "AUGraphNodeInfo failed");
}

- (void)createRemoteIONodeToGraph:(AUGraph*)graph {
    
}

- (void)setupSession{
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    [session setActive:YES error:nil];
}


@end
