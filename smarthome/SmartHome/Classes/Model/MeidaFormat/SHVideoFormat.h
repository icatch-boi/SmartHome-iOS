//
//  SHVideoFormat.h
//  SmartHome
//
//  Created by ZJ on 2017/12/25.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHVideoFormat : NSObject

@property (nonatomic, copy) NSString *mineType;
@property (nonatomic, assign) int codec;
@property (nonatomic, assign) int videoW;
@property (nonatomic, assign) int videoH;
@property (nonatomic, assign) uint bitrate;
@property (nonatomic, assign) int durationUs;
@property (nonatomic, assign) int maxInputSize;

@property (nonatomic, assign) int csd_0_size;
@property (nonatomic, strong) NSData* csd_0;

@property (nonatomic, assign) int csd_1_size;
@property (nonatomic, strong) NSData* csd_1;

@property (nonatomic, assign) uint fps;
@property (nonatomic, assign) int gop;

+ (instancetype)videoFormatWithICatchVideoFormat:(ICatchVideoFormat)format;
+ (ICatchVideoFormat *)ICatchVideoFormatFromVideoFormatWith:(SHVideoFormat *)format;

@end
