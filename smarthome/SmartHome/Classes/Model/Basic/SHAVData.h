//
//  SHCameraAVData.h
//  SmartHome
//
//  Created by ZJ on 2017/4/18.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHAVData : NSObject

@property (nonatomic) double time;
@property (nonatomic) NSMutableData *data;
@property (nonatomic) int state;
@property (nonatomic) BOOL isIFrame;

+ (instancetype)cameraAVDataWithData:(NSMutableData *)nData andTime:(double)nTime;

@end
