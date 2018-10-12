//
//  SHH264Decoder.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@interface H264Decoder : NSObject

//- (BOOL)initH264Env:(ICatchVideoFormat)format;
- (BOOL)initH264EnvWithSPSSize:(int)spsSize sps:(const unsigned char *)sps ppsSize:(int)ppsSize pps:(const unsigned char *)pps;
- (void)clearH264Env;
- (void)decodeAndDisplayH264Frame:(NSData *)frame andAVSLayer:(AVSampleBufferDisplayLayer *)avslayer;
- (UIImage *)imageFromPixelBufferRef:(NSData *)data;

@end
