//
//  SHPVOperateManageer.h
//  SmartHome
//
//  Created by ZJ on 2017/4/25.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define DataDisplayImmediately 0

@interface SHStreamOperate : NSObject

@property (nonatomic, weak) SHCameraObject *shCamObj;
@property (nonatomic, getter = isPVRun, readonly) BOOL PVRun;
@property (nonatomic) BOOL isBuffering;

- (instancetype)initWithCameraObject:(SHCameraObject *)shCamObj;
- (void)initAVSLayer:(AVSampleBufferDisplayLayer *)avslayer bufferingBlock:(void (^)(BOOL isBuffering, BOOL timeout))bufferingBlock;
- (void)startMediaStreamWithEnableAudio:(BOOL)enableAudio file:(ICatchFile *)file successBlock:(void (^)())successBlock failedBlock:(void (^)(NSInteger errorCode))failedBlock target:(id)aTarget streamCloseCallback:(SEL)streamCloseCallback;
- (int)play;
- (void)stopMediaStreamWithComplete:(void(^)())completeBlock;
- (BOOL)pause;
- (BOOL)resume;
- (BOOL)seek:(double)point;
- (void)isMute:(BOOL)mute successBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)openAudioServerWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)closeAudioServer;
- (void)startTalkBackWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)stopTalkBackWithSuccessBlock:(void (^)())successBlock failedBlock:(void (^)())failedBlock;
- (BOOL)stopTalkBack;
- (void)stillCaptureWithSuccessBlock:(void(^)())successBlock failedBlock:(void (^)())failedBlock;
- (void)updatePreviewThumbnail;
- (void)uploadPreviewThumbnailToServer;
- (void)stopPreview;
- (void)initDisplayImageView:(UIImageView *)displayImageView bufferingBlock:(void (^)(BOOL isBuffering, BOOL timeout))bufferingBlock;

- (UIImage *)getLastFrameImage;

@end
