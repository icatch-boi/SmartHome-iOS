//
//  SHAudioFormat.h
//  SmartHome
//
//  Created by ZJ on 2017/12/25.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHAudioFormat : NSObject

@property (nonatomic, assign) int codec;
@property (nonatomic, assign) int frequency;
@property (nonatomic, assign) int sampleBits;
@property (nonatomic, assign) int nChannels;

+ (instancetype)audioFormatWithICatchAudioFormat:(ICatchAudioFormat)format;
+ (ICatchAudioFormat *)ICatchAudioFormatFromAudioFormatWith:(SHAudioFormat *)format;

@end
