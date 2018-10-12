//
//  SHCameraPlaybackControl.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHPlaybackControl.h"

@implementation SHPlaybackControl

- (double)play:(ICatchFile *)file camera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk play:file];
}

- (BOOL)pauseWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk pause];
}

- (BOOL)resumeWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk resume];
}

- (BOOL)stopWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk stop];
}

- (BOOL)seek:(double)point camera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk seek:point];
}

- (BOOL)videoPlaybackStreamEnabledWithCamera:(SHCameraObject *)cameraObj {
    __block BOOL retVal = NO;
    dispatch_sync([cameraObj.sdk sdkQueue], ^{
        retVal = [cameraObj.sdk videoPlaybackStreamEnabled];
    });
    
    return retVal;
}

- (BOOL)audioPlaybackStreamEnabledWithCamera:(SHCameraObject *)cameraObj {
    __block BOOL retVal = NO;
    dispatch_sync([cameraObj.sdk sdkQueue], ^{
        retVal = [cameraObj.sdk audioPlaybackStreamEnabled];
    });
    
    return retVal;
}

- (ICatchVideoFormat)retrievePlaybackVideoFormatWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk getPlaybackVideoFormat];
}

- (ICatchAudioFormat)retrievePlaybackAudioFormatWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk getPlaybackAudioFormat];
}

- (SHAVData *)prepareDataForPlaybackVideoFrameWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk getPlaybackVideoFrameData];
}

- (SHAVData *)prepareDataForPlaybackAudioTrackWithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk getPlaybackAudioFrameData];
}

- (ICatchFrameBuffer *)prepareDataForPlaybackAudioTrack1WithCamera:(SHCameraObject *)cameraObj {
    return [cameraObj.sdk getPlaybackAudioFrameData1];
}

@end
