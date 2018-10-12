//
//  SHVideoFormat.m
//  SmartHome
//
//  Created by ZJ on 2017/12/25.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHVideoFormat.h"

@implementation SHVideoFormat

+ (instancetype)videoFormatWithICatchVideoFormat:(ICatchVideoFormat)format {
    SHVideoFormat *instance = [SHVideoFormat new];
    
    instance.mineType = [NSString stringWithFormat:@"%s", format.getMineType().c_str()];
    instance.codec = format.getCodec();
    instance.videoW = format.getVideoW();
    instance.videoH = format.getVideoH();
    instance.bitrate = format.getBitrate();
    instance.durationUs = format.getDurationUs();
    instance.maxInputSize = format.getMaxInputSize();
    instance.csd_0_size = format.getCsd_0_size();
    
//    instance.csd_0 = (unsigned char *)malloc(format.getCsd_0_size());
//    memcpy((void *)instance.csd_0, format.getCsd_0(), instance.csd_0_size);
    instance.csd_0 = [NSData dataWithBytes:format.getCsd_0() length:format.getCsd_0_size()];
    
    instance.csd_1_size = format.getCsd_1_size();
    
//    instance.csd_1 = (unsigned char *)malloc(format.getCsd_1_size());
//    memcpy((void *)instance.csd_1, format.getCsd_1(), instance.csd_1_size);
    instance.csd_1 = [NSData dataWithBytes:format.getCsd_1() length:format.getCsd_1_size()];
    
    instance.fps = format.getFps();
    
    return instance;
}

+ (ICatchVideoFormat *)ICatchVideoFormatFromVideoFormatWith:(SHVideoFormat *)format {
    ICatchVideoFormat *videoFormat = new ICatchVideoFormat();
    
    videoFormat->setMineType(format.mineType.UTF8String);
    videoFormat->setCodec(format.codec);
    videoFormat->setVideoW(format.videoW);
    videoFormat->setVideoH(format.videoH);
    videoFormat->setBitrate(format.bitrate);
    videoFormat->setDurationUs(format.durationUs);
    videoFormat->setMaxInputSize(format.maxInputSize);
    videoFormat->setCsd_0((const unsigned char *)format.csd_0.bytes, format.csd_0_size);
    videoFormat->setCsd_1((const unsigned char *)format.csd_1.bytes, format.csd_1_size);
    videoFormat->setFps(format.fps);
    videoFormat->setGOP(format.gop);
    
    return videoFormat;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.mineType forKey:@"mineType"];
    [aCoder encodeObject:@(self.codec) forKey:@"codec"];
    [aCoder encodeObject:@(self.videoW) forKey:@"videoW"];
    [aCoder encodeObject:@(self.videoH) forKey:@"videoH"];
    [aCoder encodeObject:@(self.bitrate) forKey:@"bitrate"];
    [aCoder encodeObject:@(self.durationUs) forKey:@"durationUs"];
    [aCoder encodeObject:@(self.maxInputSize) forKey:@"maxInputSize"];
    [aCoder encodeObject:@(self.csd_0_size) forKey:@"csd_0_size"];
    [aCoder encodeObject:self.csd_0 forKey:@"csd_0"];
    [aCoder encodeObject:@(self.csd_1_size) forKey:@"csd_1_size"];
    [aCoder encodeObject:self.csd_1 forKey:@"csd_1"];
    [aCoder encodeObject:@(self.fps) forKey:@"fps"];
    [aCoder encodeObject:@(self.gop) forKey:@"gop"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [[self class] new];
    if (self)
    {
        self.mineType = [aDecoder decodeObjectForKey:@"mineType"];
        self.codec = [[aDecoder decodeObjectForKey:@"codec"] intValue];
        self.videoW = [[aDecoder decodeObjectForKey:@"videoW"] intValue];
        self.videoH = [[aDecoder decodeObjectForKey:@"videoH"] intValue];
        self.bitrate = [[aDecoder decodeObjectForKey:@"bitrate"] unsignedIntValue];
        self.durationUs = [[aDecoder decodeObjectForKey:@"durationUs"] intValue];
        self.maxInputSize = [[aDecoder decodeObjectForKey:@"maxInputSize"] intValue];
        self.csd_0_size = [[aDecoder decodeObjectForKey:@"csd_0_size"] intValue];
        self.csd_0 = [aDecoder decodeObjectForKey:@"csd_0"];
        self.csd_1_size = [[aDecoder decodeObjectForKey:@"csd_1_size"] intValue];
        self.csd_1 = [aDecoder decodeObjectForKey:@"csd_1"];
        self.fps = [[aDecoder decodeObjectForKey:@"fps"] unsignedIntValue];
        self.gop = [[aDecoder decodeObjectForKey:@"gop"] intValue];
    }
    return self;
}

@end
