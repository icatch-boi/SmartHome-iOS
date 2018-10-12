//
//  SHCameraAVData.m
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import "SHAVData.h"

@implementation SHAVData

+ (instancetype)cameraAVDataWithData:(NSMutableData *)nData andTime:(double)nTime {
    SHAVData *avData = [[SHAVData alloc] init];
    avData.data = nData;
    avData.time = nTime;
    
    return avData;
}

@end
