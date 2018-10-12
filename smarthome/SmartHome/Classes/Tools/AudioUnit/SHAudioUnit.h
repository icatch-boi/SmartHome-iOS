//
//  SHAudioUnit.h
//  SmartHome
//
//  Created by ZJ on 2017/8/28.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHAudioUnit : NSObject

@property (nonatomic, weak) SHCameraObject *shCameraObj;

- (void)startAudioRecord;
- (void)stopAudioRecord;

@end
