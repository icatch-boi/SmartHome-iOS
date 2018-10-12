//
//  SHCameraPlaybackControl.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHPlaybackControl : NSObject

- (double)play:(ICatchFile *)file camera:(SHCameraObject *)cameraObj;
- (BOOL)pauseWithCamera:(SHCameraObject *)cameraObj;
- (BOOL)resumeWithCamera:(SHCameraObject *)cameraObj;
- (BOOL)stopWithCamera:(SHCameraObject *)cameraObj;
- (BOOL)seek:(double)point camera:(SHCameraObject *)cameraObj;
- (BOOL)videoPlaybackStreamEnabledWithCamera:(SHCameraObject *)cameraObj;
- (BOOL)audioPlaybackStreamEnabledWithCamera:(SHCameraObject *)cameraObj;

- (ICatchVideoFormat)retrievePlaybackVideoFormatWithCamera:(SHCameraObject *)cameraObj;
- (ICatchAudioFormat)retrievePlaybackAudioFormatWithCamera:(SHCameraObject *)cameraObj;
- (SHAVData *)prepareDataForPlaybackVideoFrameWithCamera:(SHCameraObject *)cameraObj;
- (SHAVData *)prepareDataForPlaybackAudioTrackWithCamera:(SHCameraObject *)cameraObj;
- (ICatchFrameBuffer *)prepareDataForPlaybackAudioTrack1WithCamera:(SHCameraObject *)cameraObj;

@end
