//
//  SHAudioUnitRecord.h
//  SmartHome
//
//  Created by ZJ on 2017/11/24.
//  Copyright © 2017年 ZJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SHAudioUnitRecord : NSObject

- (instancetype)initWithCameraObj:(SHCameraObject *)obj;
- (void)startAudioUnit;
- (void)stopAudioUnit;

@end
