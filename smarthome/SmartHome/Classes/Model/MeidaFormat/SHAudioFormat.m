//
//  SHAudioFormat.m
//  SmartHome
//
//  Created by ZJ on 2017/12/25.
//  Copyright © 2017年 iCatch Technology Inc. All rights reserved.
//

#import "SHAudioFormat.h"

@implementation SHAudioFormat

+ (instancetype)audioFormatWithICatchAudioFormat:(ICatchAudioFormat)format {
    SHAudioFormat *instance = [SHAudioFormat new];
    
    instance.codec = format.getCodec();
    instance.frequency = format.getFrequency();
    instance.sampleBits = format.getSampleBits();
    instance.nChannels = format.getNChannels();
    
    return instance;
}

+ (ICatchAudioFormat *)ICatchAudioFormatFromAudioFormatWith:(SHAudioFormat *)format {
    ICatchAudioFormat *audioFormat = new ICatchAudioFormat();
    
    audioFormat->setCodec(format.codec);
    audioFormat->setFrequency(format.frequency);
    audioFormat->setSampleBits(format.sampleBits);
    audioFormat->setNChannels(format.nChannels);
    
    return audioFormat;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(self.codec) forKey:@"codec"];
    [aCoder encodeObject:@(self.frequency) forKey:@"frequency"];
    [aCoder encodeObject:@(self.sampleBits) forKey:@"sampleBits"];
    [aCoder encodeObject:@(self.nChannels) forKey:@"nChannels"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [[self class] new];
    if (self)
    {
        self.codec = [[aDecoder decodeObjectForKey:@"codec"] intValue];
        self.frequency = [[aDecoder decodeObjectForKey:@"frequency"] intValue];
        self.sampleBits = [[aDecoder decodeObjectForKey:@"sampleBits"] intValue];
        self.nChannels = [[aDecoder decodeObjectForKey:@"nChannels"] unsignedIntValue];
    }
    return self;
}

@end
